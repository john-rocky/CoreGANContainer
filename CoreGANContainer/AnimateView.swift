//
//  AnimateView.swift
//  AI.Painter
//
//  Created by 間嶋大輔 on 2020/03/27.
//  Copyright © 2020 daisuke. All rights reserved.
//

import UIKit
import ReplayKit
import AudioToolbox
import StoreKit

extension ViewController {
    func addAnimateViews(){
        view.addSubview(fullSizeImageView)
        view.addSubview(fullSizeImageView1)

        fullSizeImageView.isHidden = true
        fullSizeImageView1.isHidden = true

        fullSizeImageView.frame = view.bounds
        fullSizeImageView1.frame = view.bounds

        fullSizeImageView.contentMode = .scaleAspectFit
        fullSizeImageView1.contentMode = .scaleAspectFit
       
    }
    
    func slideShow(){
        animatedLabel.text = "Result"
        imageView.isHidden = true
        navAndCollectionHidding()
        fullSizeImageView.isHidden = false
        fullSizeImageView1.isHidden = false
        
        originalLabel.alpha = 0
        animatedLabel.alpha = 0
        originalLabel.isHidden = false
        animatedLabel.isHidden = false

        if !isRecording {
        fullSizeImageView.alpha = 0
        }
        fullSizeImageView1.alpha = 0

        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1, delay: 0, options: [], animations: {
            self.fullSizeImageView.alpha = 1
            self.originalLabel.alpha = 1
        }) { (UIViewAnimatingPosition) in
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1, delay: 1, options: [], animations: {
                self.fullSizeImageView.alpha = 0
                self.originalLabel.alpha = 0

                self.fullSizeImageView1.alpha = 1
                self.animatedLabel.alpha = 1

            }) { (UIViewAnimatingPosition) in
                            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                                self.fullSizeImageView.isHidden = true
                                self.fullSizeImageView1.isHidden = true
                                self.originalLabel.isHidden = true
                                self.animatedLabel.isHidden = true
                                self.imageView.isHidden = false
                                var time:TimeInterval = 1
                                if self.isRecording {
                                    time = 3
                                } else {
                                    time = 1
                                }
                                
                                Timer.scheduledTimer(withTimeInterval: time, repeats: false) { (Timer) in
                                if self.isRecording {
                                    self.sharedRecorder.stopRecording(handler: { (previewViewController, error) in
                                        previewViewController?.previewControllerDelegate = self
                                        self.present(previewViewController!, animated: true, completion: nil)
                                        })
                                AudioServicesPlaySystemSound(1118)
                                    self.recLabel.isHidden = true
                                    self.isRecording = false
                                } else {
                                    self.playHapticsFile("DogHelloSmile")
                                }
                                self.backgroundView.isHidden = false

                                self.navAndCollectionAppearing()
                            }
                }
                        }
                    }
                }
           
            
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        DispatchQueue.main.async { [unowned previewController] in
            previewController.dismiss(animated: true, completion: nil)
            var saveCount = UserDefaults.standard.integer(forKey: "saveCount")
            saveCount += 1
            UserDefaults.standard.set(saveCount, forKey: "saveCount")
            let infoDictionaryKey = kCFBundleVersionKey as String
            guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { return }
            let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: "version")
            if saveCount == 2 && currentVersion != lastVersionPromptedForReview {
                       DispatchQueue.main.async{
                               SKStoreReviewController.requestReview()
                               UserDefaults.standard.set(currentVersion, forKey: "version")
                        saveCount = 0
                        UserDefaults.standard.set(saveCount, forKey: "saveCount")
                       }
            }
        }
    }
    
    func rec(){
        imageView.isHidden = true
         self.fullSizeImageView.isHidden = false
        fullSizeImageView.alpha = 1        
        recLabel.text = NSLocalizedString("CaricatureU Recording", comment: "")
        view.addSubview(recLabel)
        recLabel.textAlignment = .center
        recLabel.textColor = .red
        recLabel.frame = CGRect(x: 0, y: view.bounds.height * 0.05, width: view.bounds.width, height: view.bounds.height * 0.05)
        recLabel.font = .systemFont(ofSize: 20,weight:.heavy)
        isRecording = true
        self.recLabel.isHidden = false
        AudioServicesPlaySystemSound(1117)
 
        
        sharedRecorder.startRecording(handler: { (error) in
            if let error = error {
                print(error)
            }
            self.slideShow()
            self.backgroundView.isHidden = true
            })
    }
}
