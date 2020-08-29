//
//  ViewController.swift
//  CoreGANContainer
//
//  Created by 間嶋大輔 on 2020/08/26.
//  Copyright © 2020 daisuke. All rights reserved.
//

import UIKit
import Vision
import ReplayKit
import CoreHaptics
import CoreML

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,RPPreviewViewControllerDelegate {
    // Models
    var modelUrls: [URL]!
    var selectedVNModel: VNCoreMLModel?
    var selectedModel: MLModel?
    var coreMLRequest:VNCoreMLRequest?
    lazy var rotateRequest:VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest(completionHandler: rotateCompletionHandler)
        request.revision = VNDetectFaceRectanglesRequestRevision2
        return request
    }()
    lazy var faceCropRequest:VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest(completionHandler: cropCompletionHandler)
        request.revision = VNDetectFaceRectanglesRequestRevision2
        return request
    }()
    // Inputs
    var isImageInput = true
    var isImageOutput = false
    var toggleInputImage = UISwitch()
    var isSelfieLabel = UILabel()
    var isSelfie = false
    var inputImageScaleButton = UISegmentedControl(items: ["Center","ScaleFit","ScaleFill"])
    var outputShapeButton = UISegmentedControl(items: ["CWH","WHC","BGR"])
    
    var isSquare = true
    enum PickMode {
        case camera
        case photo
    }
    enum OutputShape {
        case WHC
        case CWH
        case BGR
    }
    enum InputScale {
        case centerCrop
        case scaleAspectFill
        case scaleAspectFit
    }
    var pickMode:PickMode = .camera
    var inputScale:InputScale = .centerCrop
    var outputShape:OutputShape = .CWH
    var isVideo = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let modelPaths = Bundle.main.paths(forResourcesOfType: "mlmodel", inDirectory: "models")
        modelUrls = []
        for modelPath in modelPaths {
            let url = URL(fileURLWithPath: modelPath)
            self.modelUrls.append(url)
        }
        selectModel(url:modelUrls.first!)

        if supportsHaptics {
            createEngine()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        viewsSetting()
        addAnimateViews()
        progressSetting()
        buttonSetting()
        navAndCollectionHidding()
        
        navigationController?.navigationBar.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: true)
        buttonAdding()
    }
    
    func request(_ request:VNRequest,_ image:CIImage){
        let handler = VNImageRequestHandler(ciImage: image,options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
        DispatchQueue.main.async {
            self.view.isUserInteractionEnabled = false
            self.progressLabel.isHidden = false
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            var newImage = UIImage()
            switch pickedImage.imageOrientation.rawValue {
            case 1:
                newImage = imageRotatedByDegrees(oldImage: pickedImage, deg: 180)
            case 3:
                newImage = imageRotatedByDegrees(oldImage: pickedImage, deg: 90)
            default:
                newImage = pickedImage
            }
            originalUIImageSize = newImage.size
            if originalUIImageSize?.width == originalUIImageSize?.height {
                isSquare = true
            } else {
                isSquare = false
            }
            imageView.isHidden = true
            originalUIImage = newImage
            navAndCollectionAppearing()
            buttonHidding()
            originalCIImage = CIImage(image: newImage)
            if isVideo {
                let model = coreMLRequest?.model
                coreMLRequest = VNCoreMLRequest(model: model!, completionHandler: coreMLCompletionHandler(request:error:))
                isVideo = false
            }

            if isSelfie {
                request(rotateRequest, originalCIImage!)
            } else {
                request(coreMLRequest!, originalCIImage!)
            }
            picker.dismiss(animated: true)
            DispatchQueue.main.async {
                self.progressStart()
            }
        }
        
        if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            buttonHidding()
            isVideo = true
            let model = coreMLRequest?.model
            coreMLRequest = VNCoreMLRequest(model: model!, completionHandler: videoMLCompletionHandler(request:error:))
            assetFromFrame(videoUrl: videoUrl)
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func selectModel(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let compiledUrl = try! MLModel.compileModel(at: url)
                let mlmodel = try! MLModel(contentsOf: compiledUrl)
                if !mlmodel.modelDescription.inputDescriptionsByName.values.description.contains("Image") {
                    self.isImageInput = false
                } else {
                    self.isImageInput = true
                }
                if !mlmodel.modelDescription.outputDescriptionsByName.values.description.contains("Image") {
                    self.isImageOutput = false
                } else {
                    self.isImageOutput = true
                }
                print(mlmodel.modelDescription.inputDescriptionsByName.values.first!)
                print(mlmodel.modelDescription.outputDescriptionsByName.values.first!)

                let model = try VNCoreMLModel(for: mlmodel)
                self.coreMLRequest = VNCoreMLRequest(model: model,completionHandler: self.coreMLCompletionHandler(request:error:))
                DispatchQueue.main.async {
                    self.selectButton.text = url.modelName
                }
            }
            catch {
                fatalError("Could not create VNCoreMLModel instance from \(url). error: \(error).")
            }
        }
    }
    
    // Images
    var originalCIImage:CIImage?
    var croppedCIImage:CIImage?
    var rotatedCIImage:CIImage?
    var originalUIImage:UIImage?
    var resizedCroppedUI:UIImage?
    var context = CIContext()
    var GPU = true
    var originalUIImageSize:CGSize?
    // For Video
    var samples:[CVPixelBuffer] = []
    var assetWriter: AVAssetWriter!
    var videoAssetInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    var startTime: CMTime!
    var endTime: CMTime!
    var frameNumber: Int64 = 0
    var frameTime:CMTime!
    var assetFrameCount = 0
    var frameCount = 0
    var fps:Double = 24
    var durationForEachImage = 0.1
    var fileName:String = "0"
    var assetTimeScale:Double?
    var assetFramesCount:Double?
    var videoTrack: AVAssetTrack!
    var assetReader: AVAssetReader!
    var videoAssetReaderOutput: AVAssetReaderTrackOutput!
    // Top Views
    var selectButton = UILabel()
    var runButton = UILabel()
    // Menu Views
    var RestartButton = UIImageView()
    var activityButton = UIImageView()
    var HelpButton = UIImageView()
    var SaveButton = UIImageView()
    var backgroundView = UIView()
    // Result Views
    var imageView = UIImageView()
    var edittedImageView = UIImageView()
    var croppedImageView = UIImageView()
    var progressView = UIProgressView()
    var progress:Float = 0.0
    var timer:Timer!
    var progressLabel = UILabel()
    var originalLabel = UILabel()
    var animatedLabel = UILabel()
    // Recording Views
    var fullSizeImageView = UIImageView()
    var fullSizeImageView1 = UIImageView()
    var recLabel = UILabel()
    var isRecording = false
    let sharedRecorder = RPScreenRecorder.shared()
    // Haptics
    var engine: CHHapticEngine!
    lazy var supportsHaptics: Bool = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.supportsHaptics
    }()

}
