//
//  VisionRequests.swift
//  Mask
//
//  Created by 間嶋大輔 on 2020/04/28.
//  Copyright © 2020 daisuke. All rights reserved.
//

import AVFoundation
import Vision
import UIKit
import Photos
import AVKit

extension ViewController:AVPlayerViewControllerDelegate {
    
    func coreMLCompletionHandler(request:VNRequest?,error:Error?) {
        if !isImageOutput {
        let result = request?.results?.first as! VNCoreMLFeatureValueObservation
        let multiArray = result.featureValue.multiArrayValue
        if multiArray![0].floatValue.isNaN, GPU {
            print(multiArray![0])
            GPU = false
            coreMLRequest!.usesCPUOnly = true
            self.request(coreMLRequest!, croppedCIImage!)
        } else if multiArray![0].floatValue.isNaN, !GPU {
            DispatchQueue.main.async {
                self.presentAlert(NSLocalizedString("Conversion failed. Compatible only with A13 chip or later", comment: ""))
                self.buttonAppearing()
                self.navAndCollectionHidding()
                self.view.isUserInteractionEnabled = true
            }
        } else {
            var cgimage:CGImage?
            switch outputShape {
            case .WHC:
                cgimage = multiArray?.cgImage(min: -1, max: 1, channel: nil)
            case .CWH:
                cgimage = multiArray?.cgImage(min: -1, max: 1, channel: nil, axes: (3,1,2))
            case .BGR:
                cgimage = multiArray?.cgImage(min: -1, max: 1, channel: nil, axes: (3,1,2))?.toBGR()
            }
            if cgimage == nil {
                DispatchQueue.main.async {
                    self.presentAlert(NSLocalizedString("Invalid Output Shape.Try other option.", comment: ""))
                    self.Restart()
                    self.view.isUserInteractionEnabled = true
                }
                return
            }
            DispatchQueue.main.async {
                self.croppedImageView.image = self.originalUIImage
                self.fullSizeImageView.image = self.originalUIImage
                }
    
            let uiimage = UIImage(cgImage: cgimage!)
            if !isSquare {
                uiimage.resize(size: originalUIImageSize!)
            }
            DispatchQueue.main.async {
                self.progress = 1.0
                self.progressView.setProgress(self.progress, animated: true)
                self.progressLabel.text = NSLocalizedString("Complete !", comment: "")
                self.progressLabel.isHidden = true
                self.progressView.isHidden = true
                self.croppedImageView.image = self.originalUIImage
                self.edittedImageView.image = uiimage
                self.fullSizeImageView1.image = uiimage
                self.slideShow()
                self.view.isUserInteractionEnabled = true
            }
        }
        } else {
            let result = request?.results?.first as! VNPixelBufferObservation
            let uiimage = UIImage(ciImage: CIImage(cvPixelBuffer: result.pixelBuffer))
            if !isSquare {
                uiimage.resize(size: originalUIImageSize!)
            }
            DispatchQueue.main.async {
                self.croppedImageView.image = self.originalUIImage
                self.fullSizeImageView.image = self.originalUIImage
                }
            DispatchQueue.main.async {
                self.progress = 1.0
                self.progressView.setProgress(self.progress, animated: true)
                self.progressLabel.text = NSLocalizedString("Complete !", comment: "")
                self.progressLabel.isHidden = true
                self.progressView.isHidden = true
                self.edittedImageView.image = uiimage
                self.fullSizeImageView1.image = uiimage
                self.slideShow()
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func videoMLCompletionHandler(request:VNRequest?,error:Error?) {
        if !isImageOutput {
        let result = request?.results?.first as! VNCoreMLFeatureValueObservation
        let multiArray = result.featureValue.multiArrayValue
        if multiArray![0].floatValue.isNaN, GPU {
            print(multiArray![0])
            GPU = false
            coreMLRequest!.usesCPUOnly = true
            self.request(coreMLRequest!, croppedCIImage!)
        } else if multiArray![0].floatValue.isNaN, !GPU {
            DispatchQueue.main.async {
                self.presentAlert(NSLocalizedString("変換に失敗しました。A13チップ以降とのみ互換性があります", comment: ""))
                self.view.isUserInteractionEnabled = true
            }
        } else {
            var cgimage:CGImage?
            switch outputShape {
            case .WHC:
                cgimage = multiArray?.cgImage(min: -1, max: 1, channel: nil)
            case .CWH:
                cgimage = multiArray?.cgImage(min: -1, max: 1, channel: nil, axes: (3,1,2))
            case .BGR:
                cgimage = multiArray?.cgImage(min: -1, max: 1, channel: nil, axes: (3,1,2))?.toBGR()
            }
            if cgimage == nil {
                DispatchQueue.main.async {
                    self.presentAlert(NSLocalizedString("Invalid Output Shape.Try other option.", comment: ""))
                    self.Restart()
                    self.view.isUserInteractionEnabled = true
                }
                return
            }
            guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
                fatalError("Failed to allocate the PixelBufferPool")
            }
            var pixelBufferOut: CVPixelBuffer? = nil
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
            
            guard let pixelBuffer = pixelBufferOut else {
                fatalError("Failed to create the PixelBuffer")
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(pixelBuffer),
                width: cgimage!.width,
                height: cgimage!.height,
                bitsPerComponent: cgimage!.bitsPerComponent,
                bytesPerRow: cgimage!.bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: cgimage!.bitmapInfo.rawValue)
            context?.draw(cgimage!, in: cgimage!.frame)
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            if videoAssetInput.isReadyForMoreMediaData {
                
                frameTime = CMTimeMake(value: Int64(Double(frameCount)), timescale: Int32(fps))
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
                frameCount += 1
                print(frameTime)
                if samples.count == 1{
                    videoAssetInput.markAsFinished()
                    assetWriter.endSession(atSourceTime: frameTime)
                    assetWriter.finishWriting(completionHandler: {
                        print("comp")
                        //            self.buffers.removeAll()
                        guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(self.fileName + ".mp4") else {return}
                        let data = try? Data(contentsOf: url)
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        }) { saved, error in
                            if saved {
                                let fetchOptions = PHFetchOptions()
                                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                }
                        }
                        
                        // Modally present the player and call the player's play() method when complete.
                        DispatchQueue.main.async {
                            self.progress = 1.0
                            self.progressView.setProgress(self.progress, animated: true)
                            self.progressLabel.text = NSLocalizedString("Complete !", comment: "")
                            self.progressLabel.isHidden = true
                            self.progressView.isHidden = true
                            self.buttonAppearing()
                            self.navAndCollectionHidding()
                            self.view.isUserInteractionEnabled = true
                            let player = AVPlayer(url: url)
                            
                            let controller = AVPlayerViewController()
                            controller.player = player
                            self.present(controller, animated: true) {
                                player.play()
                            }
                        }
                    })
                }else {
                    appendBuffer()
                }
            } else {
                print("no")
            }
        }
        } else {
            let result = request?.results?.first as! VNPixelBufferObservation
            let cgimage = CIImage(cvImageBuffer: result.pixelBuffer).cgImage
            guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
                    fatalError("Failed to allocate the PixelBufferPool")
                }
                var pixelBufferOut: CVPixelBuffer? = nil
                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
                
                guard let pixelBuffer = pixelBufferOut else {
                    fatalError("Failed to create the PixelBuffer")
                }
                
                CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                
                let context = CGContext(
                    data: CVPixelBufferGetBaseAddress(pixelBuffer),
                    width: cgimage!.width,
                    height: cgimage!.height,
                    bitsPerComponent: cgimage!.bitsPerComponent,
                    bytesPerRow: cgimage!.bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: cgimage!.bitmapInfo.rawValue)
                context?.draw(cgimage!, in: cgimage!.frame)
                
                CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                if videoAssetInput.isReadyForMoreMediaData {
                    
                    frameTime = CMTimeMake(value: Int64(Double(frameCount)), timescale: Int32(fps))
                    pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
                    frameCount += 1
                    print(frameTime)
                    if samples.count == 1{
                        videoAssetInput.markAsFinished()
                        assetWriter.endSession(atSourceTime: frameTime)
                        assetWriter.finishWriting(completionHandler: {
                            print("comp")
                            //            self.buffers.removeAll()
                            guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(self.fileName + ".mp4") else {return}
                            let data = try? Data(contentsOf: url)
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                            }) { saved, error in
                                if saved {
                                    let fetchOptions = PHFetchOptions()
                                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                                    }
                            }
                            
                            // Modally present the player and call the player's play() method when complete.
                            DispatchQueue.main.async {
                                self.progress = 1.0
                                self.progressView.setProgress(self.progress, animated: true)
                                self.progressLabel.text = NSLocalizedString("Complete !", comment: "")
                                self.progressLabel.isHidden = true
                                self.progressView.isHidden = true
                                self.buttonAppearing()
                                self.navAndCollectionHidding()
                                self.view.isUserInteractionEnabled = true
                                let player = AVPlayer(url: url)
                                
                                let controller = AVPlayerViewController()
                                controller.player = player
                                self.present(controller, animated: true) {
                                    player.play()
                                }
                            }
                        })
                    }else {
                        appendBuffer()
                    }
                } else {
                    print("no")
                }
            
        }
    }
    
    

    
    func rotateCompletionHandler(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            DispatchQueue.main.async {
                self.buttonAppearing()
                self.navAndCollectionHidding()
                self.view.isUserInteractionEnabled = true
                self.presentAlert(NSLocalizedString("Face detection failed",comment: ""))
                self.progressView.isHidden = true
                self.progressLabel.isHidden = true
            }
            return
        }
        guard let results = self.rotateRequest.results as? [VNFaceObservation] else {
            DispatchQueue.main.async {
                self.buttonAppearing()
                self.navAndCollectionHidding()
                self.view.isUserInteractionEnabled = true
                self.presentAlert(NSLocalizedString("Face detection failed",comment: ""))
            }
            return
        }
        if results.count == 0 {
            DispatchQueue.main.async {
                self.buttonAppearing()
                self.navAndCollectionHidding()
                self.view.isUserInteractionEnabled = true
                self.presentAlert(NSLocalizedString("Face detection failed",comment: ""))
                self.progressView.isHidden = true
                self.progressLabel.isHidden = true
            }
        } else {
            
            let roll = CGFloat(truncating: (results.first?.roll)!)
            if roll != 0 {
                rotatedCIImage = originalCIImage!.transformed(by: CGAffineTransform(rotationAngle: -roll))
                let imageData = context.pngRepresentation(of: rotatedCIImage!, format: CIFormat.ARGB8, colorSpace: CGColorSpace(name: "kCGColorSpaceDisplayP3" as CFString)!)
                rotatedCIImage = CIImage(data: imageData!)
                self.request(faceCropRequest, rotatedCIImage!)
                self.progress = 0.25
                DispatchQueue.main.async {
                self.progressView.setProgress(self.progress, animated: true)
                }
            } else {
                let boundingBox = results.first!.boundingBox
                let faceRect = VNImageRectForNormalizedRect((boundingBox),Int(originalCIImage!.extent.size.width), Int(originalCIImage!.extent.size.height))
                let wideRect = CGRect(x: faceRect.minX - faceRect.width * 0.25, y: faceRect.minY - faceRect.height * 0.25, width: faceRect.width + faceRect.width * 0.5, height: faceRect.height + faceRect.height * 0.5)
                self.croppedCIImage = self.originalCIImage!.cropped(to: wideRect)
                let imageData = context.pngRepresentation(of: croppedCIImage!, format: CIFormat.ARGB8, colorSpace: CGColorSpace(name: "kCGColorSpaceDisplayP3" as CFString)!)
                croppedCIImage = CIImage(data: imageData!)
                self.request(coreMLRequest!, croppedCIImage!)
                let final = context.createCGImage (croppedCIImage!, from: croppedCIImage!.extent)
                let uiimage = UIImage(cgImage: final!)
                DispatchQueue.main.async {
                    self.croppedImageView.image = uiimage
                    self.fullSizeImageView.image = uiimage
                    self.progress = 0.5
                    self.progressView.setProgress(self.progress, animated: true)
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    func cropCompletionHandler(request: VNRequest?, error:Error?) {
        // Crop Request is original only.
        if let nsError = error as NSError? {
            DispatchQueue.main.async {
                self.presentAlert(NSLocalizedString("Face detection failed",comment: ""))
                self.buttonAppearing()
                self.navAndCollectionHidding()
                self.view.isUserInteractionEnabled = true
                self.progressView.isHidden = true
                self.progressLabel.isHidden = true
            }
            return
        }
        guard let result = faceCropRequest.results?.first as? VNFaceObservation else {
            DispatchQueue.main.async {
            self.progressView.isHidden = true
            self.progressLabel.isHidden = true
            }
            return }
        let faceBoundingBox = result.boundingBox
        let faceRect = VNImageRectForNormalizedRect(faceBoundingBox,Int(rotatedCIImage!.extent.size.width), Int(rotatedCIImage!.extent.size.height))
        let wideRect = CGRect(x: faceRect.minX - faceRect.width * 0.25, y: faceRect.minY - faceRect.height * 0.25, width: faceRect.width + faceRect.width * 0.5, height: faceRect.height + faceRect.height * 0.5)
        self.croppedCIImage = self.originalCIImage!.cropped(to: wideRect)
        let imageData = context.pngRepresentation(of: croppedCIImage!, format: CIFormat.ARGB8, colorSpace: CGColorSpace(name: "kCGColorSpaceDisplayP3" as CFString)!)
        croppedCIImage = CIImage(data: imageData!)
        self.request(coreMLRequest!, croppedCIImage!)
        let uiimage = UIImage(data: imageData!)
        DispatchQueue.main.async {
            self.croppedImageView.image = uiimage
            self.fullSizeImageView.image = uiimage
            self.progress = 0.5
            self.progressView.setProgress(self.progress, animated: true)
            self.view.isUserInteractionEnabled = true
        }
    }
}
