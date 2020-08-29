//
//  Utils.swift
//  AIFace
//
//  Created by 間嶋大輔 on 2020/03/07.
//  Copyright © 2020 daisuke. All rights reserved.
//
import UIKit
import CoreHaptics
import Photos
import Vision

extension ViewController {
    @objc func toggleIsSelfie(){
        isSelfie.toggle()
        if isSelfie {
            isSelfieLabel.text = "Selfie"
        } else {
            isSelfieLabel.text = "NotSelfie"
        }
    }
    
    @objc func selectInputScale(_ sender: UISegmentedControl){
        switch inputImageScaleButton.selectedSegmentIndex {
        case 0:
            coreMLRequest?.imageCropAndScaleOption = .centerCrop
        case 1:
            coreMLRequest?.imageCropAndScaleOption = .scaleFit
        case 2:
            coreMLRequest?.imageCropAndScaleOption = .scaleFill
        default:
            coreMLRequest?.imageCropAndScaleOption = .centerCrop
        }
    }
    
    @objc func selectOutShape(_ sender: UISegmentedControl){
        switch outputShapeButton.selectedSegmentIndex {
        case 0:
            outputShape = .CWH
        case 1:
            outputShape = .WHC
        case 2:
            outputShape = .BGR
        default:
            outputShape = .CWH
        }
        print(outputShape)
    }
    
    func assetFromFrame(videoUrl url:URL){
        videoWrite()
        let asset = AVAsset(url: url)
        assetTimeScale = Double(asset.duration.timescale)
        let assetDurationSeconds = asset.duration.seconds
        let array = asset.tracks(withMediaType: AVMediaType.video)
        self.videoTrack = array[0]
        do {
            self.assetReader = try AVAssetReader(asset: asset)
        } catch {
            print("Failed to create AVAssetReader object: \(error)")
            return
        }
        
        videoAssetReaderOutput = AVAssetReaderTrackOutput(track: self.videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
                guard self.videoAssetReaderOutput != nil else {
                    return
                }
        self.videoAssetReaderOutput.alwaysCopiesSampleData = true
        guard self.assetReader.canAdd(videoAssetReaderOutput) else {
            return
        }
        self.assetReader.add(videoAssetReaderOutput)
        self.assetReader.startReading()
        while let buffer = nextFrame()  {
            samples.append(buffer)
        }
        print("comp\(samples.count)")
        fps = Double(samples.count) / Double(assetDurationSeconds)
        assetFramesCount = Double(samples.count)
        self.progressStart()
        appendBuffer()
    }
    func nextFrame() -> CVPixelBuffer? {
        guard let sampleBuffer = self.videoAssetReaderOutput.copyNextSampleBuffer() else {
            return nil
        }
        print(sampleBuffer.duration)
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }
    
    func appendBuffer(){
        if samples.count != 0{
            DispatchQueue.global(qos: .userInitiated).async {
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: self.samples[0],options: [:])
                do {
                    try imageRequestHandler.perform([self.coreMLRequest!])
                    if self.samples.count != 1{
                        self.samples.removeFirst()
                    } else {
                        self.samples = []
                    }
                } catch {
                    print(error)
                }
            }
        } else {
            print("adaptor done!")
        }
    }
    
    func videoWrite(){
        frameNumber = 0
        frameCount = 0
        fileName = "\(Date())"
        guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(fileName + ".mp4") else { print("nil"); return}
        print(url)
        let videoSettings = [
            AVVideoWidthKey: 256,
            AVVideoHeightKey: 256,
            AVVideoCodecKey: AVVideoCodecType.h264
        ] as [String: Any]
        
        videoAssetInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        if pickMode == .camera {
        videoAssetInput.transform = CGAffineTransform(rotationAngle: 90 * CGFloat.pi / 180)
        }
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoAssetInput, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
        frameNumber = 0
        do {
            try assetWriter = AVAssetWriter(outputURL: url, fileType: .mp4)
            assetWriter.add(videoAssetInput)
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMTime.zero)
        } catch {
            print("could not start video recording ", error)
        }
    }
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        if degrees == 90 {
            let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.height, height: oldImage.size.width))
            let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
            rotatedViewBox.transform = t
            let rotatedSize: CGSize = rotatedViewBox.frame.size
            //Create the bitmap context
            UIGraphicsBeginImageContext(rotatedSize)
            let bitmap: CGContext = UIGraphicsGetCurrentContext()!
            //Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            //Rotate the image context
            bitmap.rotate(by: (degrees * CGFloat.pi / 180))
            //Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0)
            bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.height / 2, y: -oldImage.size.width / 2, width: oldImage.size.height, height: oldImage.size.width))
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return newImage
        } else {
            let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
            let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
            rotatedViewBox.transform = t
            let rotatedSize: CGSize = rotatedViewBox.frame.size
            //Create the bitmap context
            UIGraphicsBeginImageContext(rotatedSize)
            let bitmap: CGContext = UIGraphicsGetCurrentContext()!
            //Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            //Rotate the image context
            bitmap.rotate(by: (degrees * CGFloat.pi / 180))
            //Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0)
            bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return newImage
        }
    }
    
    @objc func showActionSheet() {
        let alert = UIAlertController(title: "Models", message: "Choose a model", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        for modelUrl in modelUrls {
            let action = UIAlertAction(title: modelUrl.modelName, style: .default) { (action) in
                self.selectModel(url: modelUrl)
            }
            alert.addAction(action)
        }
        present(alert, animated: true, completion: nil)
    }
    
    @objc func runModel(){
        let menu = UIAlertController(title: NSLocalizedString("Image Input Source",value: "", comment: ""), message: "", preferredStyle: .actionSheet)
        menu.addActions(actions: [
            UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { _ in
                self.pickMode = .camera
                self.imagePick()
            }),
            UIAlertAction(title: NSLocalizedString("Photo Library", comment: ""), style: .default, handler: { _ in
                self.pickMode = .photo
                self.imagePick()
            }),
            UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
            ]
        )
        menu.popoverPresentationController?.sourceView = self.view
        menu.popoverPresentationController?.sourceRect = self.view.bounds
        menu.popoverPresentationController?.permittedArrowDirections = []
        self.present(menu, animated: true, completion: nil)
    }
    
    func imagePick(){
        if isImageInput {
            switch pickMode {
            case .camera:
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                picker.cameraDevice = .rear
                picker.mediaTypes = ["public.image","public.movie"]
                self.present(picker, animated: true)
            case .photo:
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                picker.mediaTypes = ["public.image","public.movie"]
                self.present(picker, animated: true)
            }
        }
    }
    
    @objc func Help() {
        performSegue(withIdentifier: "ShowHelp", sender: nil)
    }
    
    @objc func Restart() {
        navAndCollectionHidding()
        buttonAppearing()
        imageView.image = nil
        edittedImageView.image = nil
        croppedImageView.image = nil
        imageView.isHidden = true
    }
    
    @objc func postToSNS(){
        let image = imageView.snapshot!
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
        activityViewController.popoverPresentationController?.permittedArrowDirections = []
        present(activityViewController,animated: true,completion: nil)
    }
    
    @objc func save(){
        let saveMenu = UIAlertController(title: NSLocalizedString("save",value: "", comment: ""), message: "", preferredStyle: .actionSheet)
        saveMenu.addActions(actions: [
            UIAlertAction(title: NSLocalizedString("image", comment: ""), style: .default, handler: { _ in
                self.imageSave()
            }),
            UIAlertAction(title: NSLocalizedString("slide show", comment: ""), style: .default, handler: { _ in
                self.rec()
            }),
            UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
            ]
        )
        saveMenu.popoverPresentationController?.sourceView = self.view
        saveMenu.popoverPresentationController?.sourceRect = self.view.bounds
        saveMenu.popoverPresentationController?.permittedArrowDirections = []
        self.present(saveMenu, animated: true, completion: nil)
    }
    
    func imageSave(){
        guard let image = imageView.snapshot else { self.presentAlert(NSLocalizedString("Could not save", comment: ""));return}
        guard let photoData = image.jpegData(compressionQuality: 1.0) else { self.presentAlert(NSLocalizedString("Could not save", comment: ""));return}
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    DispatchQueue.main.async {
                        self.savedNotice(image)
                    }
                }
                )
            } else {
                self.presentAlert(NSLocalizedString("Could not save", comment: ""))
            }
        }
    }
    
    func savedNotice(_ edited:UIImage) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let noticeView: SavingNoticeViewController = storyBoard.instantiateViewController(withIdentifier: "notice") as! SavingNoticeViewController
        noticeView.editedImage = edited
        //           noticeView.originalImage = UIImage(ciImage: OriginalImage)
        noticeView.modalPresentationStyle = .overFullScreen
        noticeView.modalTransitionStyle = .crossDissolve
        
        self.present(noticeView, animated: false, completion: nil)
    }
    
    func progressStart(){
        progressLabel.text = NSLocalizedString("Generating...", comment: "")
        progressLabel.isHidden = false
        progressView.isHidden = false
        progress = 0
        progressView.setProgress(progress, animated: false)
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (Timer) in
            self.progress = self.progress + 0.0005
            if self.progress < 0.9 {  //
                self.progressView.setProgress(self.progress, animated: true)
            } else {
                self.timer.invalidate()
            }
        })
    }
    
    func progressSetting(){
        view.addSubview(progressView)
        view.addSubview(progressLabel)
        progressView.frame = CGRect(x: view.bounds.width * 0.2, y: view.center.y - view.bounds.height * 0.1, width: view.bounds.width * 0.6, height: view.bounds.height * 0.1)
        progressLabel.frame = CGRect(x: view.bounds.width * 0.2, y: progressView.frame.maxY, width: view.bounds.width * 0.6, height: view.bounds.height * 0.1)
        progressLabel.text = NSLocalizedString("The AI is processing the image.", comment: "")
        progressLabel.textAlignment = .center
        progressLabel.font = .systemFont(ofSize: 20, weight: .black)
        progressLabel.textColor = .black
        progressLabel.adjustsFontSizeToFitWidth = true
        progressView.isHidden = true
        progressLabel.isHidden = true
        
    }
    
    func buttonHidding(){
        selectButton.isHidden = true
        selectButton.isUserInteractionEnabled = false
        runButton.isHidden = true
        runButton.isUserInteractionEnabled = false
        toggleInputImage.isHidden = true
        isSelfieLabel.isHidden = true
        outputShapeButton.isHidden = true
        inputImageScaleButton.isHidden = true
    }
    
    func buttonAppearing(){
        selectButton.isHidden = false
        selectButton.isUserInteractionEnabled = true
        runButton.isHidden = false
        runButton.isUserInteractionEnabled = true
        RestartButton.isHidden = false
        toggleInputImage.isHidden = false
        isSelfieLabel.isHidden = false
        outputShapeButton.isHidden = false
        inputImageScaleButton.isHidden = false
        progressView.isHidden = true
        progressLabel.isHidden = true
    }
    
    func navAndCollectionHidding(){
        RestartButton.isHidden = true
        SaveButton.isHidden = true
        activityButton.isHidden = true
    }
    
    func navAndCollectionAppearing(){
        HelpButton.isHidden = false
        RestartButton.isHidden = false
        SaveButton.isHidden = false
        activityButton.isHidden = false
    }
    
    //MARK:- Haptics
    func createEngine() {
         do {
             engine = try CHHapticEngine()
         } catch let error {
             fatalError("Engine Creation Error: \(error)")
         }
         
         engine.stoppedHandler = { reason in
             print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
             switch reason {
             case .audioSessionInterrupt: print("Audio session interrupt")
             case .applicationSuspended: print("Application suspended")
             case .idleTimeout: print("Idle timeout")
             case .notifyWhenFinished: print("Finished")
             case .systemError: print("System error")
             @unknown default:
                 print("Unknown error")
             }
         }
         engine.resetHandler = {
             print("The engine reset --> Restarting now!")

         
         do {
            try self.engine.start()
         } catch let error {
             fatalError("Engine Start Error: \(error)")
         }
     }
        do {
                   try self.engine.start()
                } catch let error {
                    fatalError("Engine Start Error: \(error)")
                }
        }
     
    func playHapticsFile(_ filename: String){
        if !supportsHaptics { return }
               
               guard let path = Bundle.main.path(forResource: filename, ofType: "ahap") else { return }
        do {
            try engine.start()
            try engine.playPattern(from: URL(fileURLWithPath: path))
        } catch {
            print("haptics error")
        }
    }
    
     func hapticsPlay(){
         do {
             let hapticPlayer = try hapticsPlayer()
             
             try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
         } catch let error {
             print("Haptic Playback Error: \(error)")
         }
     }
     
     func hapticsPlayer() throws -> CHHapticPatternPlayer? {
         let pattern = try CHHapticPattern(events: [], parameters: [])
         return try engine.makePlayer(with: pattern)
     }
    
    func presentAlert(_ title: String) {
         // Always present alert on main thread.
         DispatchQueue.main.async {
             let alertController = UIAlertController(title: title,
                                                     message: "",
                                                     preferredStyle: .alert)
             let okAction = UIAlertAction(title: NSLocalizedString("好",comment: ""),
                                          style: .default) { _ in
                                             // Do nothing -- simply dismiss alert.
             }
             alertController.addAction(okAction)
             self.present(alertController, animated: true, completion: nil)
         }
     }
}

extension UIView {
    var snapshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio

        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}

extension URL {
    var modelName: String {
        return lastPathComponent.replacingOccurrences(of: ".mlmodel", with: "")
    }
}

extension UIAlertController {
    func addActions(actions: [UIAlertAction], preferred: String? = nil) {
        for action in actions {
            self.addAction(action)
            if let preferred = preferred, preferred == action.title {
                self.preferredAction = action
            }
        }
    }
}

extension CGImage {
    var frame: CGRect {
        return CGRect(x: 0, y: 0, width: self.width, height: self.height)
    }
    
    func toBGR()->CGImage{
        let ciImage = CIImage(cgImage: self)
        let kernelStr: String = """
        kernel vec4 swapRedAndGreenAmount(__sample s) {
        return s.bgra;
        }
        """
        let ctx = CIContext(options: nil)
        let swapKernel = CIColorKernel( source:
                                            "kernel vec4 swapRedAndGreenAmount(__sample s) {" +
                                            "return s.bgra;" +
                                            "}"
        )
        let ciOutput = swapKernel?.apply(extent: (ciImage.extent), arguments: [ciImage as Any])
        let cgOut:CGImage = ctx.createCGImage(ciOutput!, from: ciOutput!.extent)!
        return cgOut
        
    }
}
