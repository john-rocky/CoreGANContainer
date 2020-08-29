//
//  Views.swift
//  CoreGANContainer
//
//  Created by 間嶋大輔 on 2020/08/28.
//  Copyright © 2020 daisuke. All rights reserved.
//

import UIKit

extension ViewController {
    func buttonAdding(){
        view.addSubview(selectButton)
        view.addSubview(runButton)
        view.addSubview(isSelfieLabel)
        view.addSubview(toggleInputImage)
        view.addSubview(inputImageScaleButton)
        view.addSubview(outputShapeButton)
        let buttonHeight = view.bounds.height * 0.1
        let buttonWidth = view.bounds.width * 0.5
        selectButton.frame = CGRect(x: view.center.x - buttonWidth * 0.5, y: view.center.y - buttonHeight - 10, width: buttonWidth, height: buttonHeight)
        runButton.frame = CGRect(x: view.center.x - buttonWidth * 0.5, y: view.center.y + 10, width: buttonWidth, height: buttonHeight)
        toggleInputImage.frame = CGRect(x: view.center.x, y: runButton.frame.maxY + 20, width: buttonWidth * 0.5, height: buttonHeight)
        isSelfieLabel.frame = CGRect(x: view.center.x - buttonWidth * 0.5, y: runButton.frame.maxY + 20, width: buttonWidth * 0.5, height: buttonHeight * 0.5)
        inputImageScaleButton.frame = CGRect(x: view.center.x - buttonWidth * 0.5, y: isSelfieLabel.frame.maxY + 20, width: buttonWidth, height: buttonHeight * 0.5)
        outputShapeButton.frame = CGRect(x: view.center.x - buttonWidth * 0.5, y: inputImageScaleButton.frame.maxY + 20, width: buttonWidth, height: buttonHeight * 0.5)
        
        runButton.text = NSLocalizedString("Run", comment: "")
        isSelfieLabel.text = "NotSelfie"

        selectButton.layer.cornerRadius = 8
        runButton.layer.cornerRadius = 8
        selectButton.clipsToBounds = true
        runButton.clipsToBounds = true
        
        selectButton.font = .systemFont(ofSize: 11, weight: .black)
        runButton.font = .systemFont(ofSize: 11, weight: .black)
        isSelfieLabel.font = .systemFont(ofSize: 11, weight: .black)
        selectButton.textAlignment = .center
        runButton.textAlignment = .center
        isSelfieLabel.textAlignment = .center

        selectButton.backgroundColor = .black
        runButton.backgroundColor = .black
        selectButton.textColor = .white
        runButton.textColor = .white
        selectButton.isUserInteractionEnabled = true
        runButton.isUserInteractionEnabled = true
        let tapSelect = UITapGestureRecognizer(target: self, action: #selector(showActionSheet))
        selectButton.addGestureRecognizer(tapSelect)
        let tapRun = UITapGestureRecognizer(target: self, action: #selector(runModel))
        runButton.addGestureRecognizer(tapRun)
        toggleInputImage.addTarget(self, action: #selector(toggleIsSelfie), for: UIControl.Event.valueChanged)
        inputImageScaleButton.addTarget(self, action:  #selector(selectInputScale(_:)), for: .valueChanged)
        inputImageScaleButton.selectedSegmentIndex = 0
        outputShapeButton.addTarget(self, action: #selector(selectOutShape(_:)), for: .valueChanged)
        outputShapeButton.selectedSegmentIndex = 0
        RestartButton.image = UIImage(systemName: "arrowshape.turn.up.left")
        activityButton.image = UIImage(systemName: "square.and.arrow.up")
        HelpButton.image = UIImage(systemName: "questionmark.circle")
        SaveButton.image = UIImage(systemName: "square.and.arrow.down")
        RestartButton.tintColor = UIColor.white
        activityButton.tintColor = UIColor.white
        HelpButton.tintColor = UIColor.white
        SaveButton.tintColor = UIColor.white
        
        backgroundView.backgroundColor = UIColor.gray
        backgroundView.alpha = 0.5
        
        let symbolConfig = UIImage.SymbolConfiguration(weight: .thin)
        
        RestartButton.preferredSymbolConfiguration = symbolConfig
        RestartButton.contentMode = .scaleAspectFill
        activityButton.preferredSymbolConfiguration = symbolConfig
        activityButton.contentMode = .scaleAspectFill
        HelpButton.preferredSymbolConfiguration = symbolConfig
        HelpButton.contentMode = .scaleAspectFill
        SaveButton.preferredSymbolConfiguration = symbolConfig
        SaveButton.contentMode = .scaleAspectFill
        view.addSubview(backgroundView)
        backgroundView.addSubview(RestartButton)
        backgroundView.addSubview(activityButton)
        backgroundView.addSubview(HelpButton)
        
        backgroundView.bringSubviewToFront(RestartButton)
        backgroundView.bringSubviewToFront(activityButton)
        backgroundView.bringSubviewToFront(HelpButton)
        backgroundView.addSubview(SaveButton)
        backgroundView.bringSubviewToFront(SaveButton)
        
        SaveButton.isUserInteractionEnabled = true
        RestartButton.isUserInteractionEnabled = true
        activityButton.isUserInteractionEnabled = true
        HelpButton.isUserInteractionEnabled = true
        
        let restartGesture = UITapGestureRecognizer(target: self, action: #selector(Restart))
        RestartButton.addGestureRecognizer(restartGesture)
        
        let helpTap = UITapGestureRecognizer(target: self, action: #selector(Help))
        
        HelpButton.addGestureRecognizer(helpTap)
        
        let postTap = UITapGestureRecognizer(target: self, action: #selector(postToSNS))
        
        activityButton.addGestureRecognizer(postTap)
        
        let recordTap = UITapGestureRecognizer(target: self, action: #selector(save))
        SaveButton.addGestureRecognizer(recordTap)
    }
    
    func buttonSetting() {
        if view.bounds.width > view.bounds.height {
            backgroundView.frame = CGRect(x: view.bounds.maxX - (view.bounds.width * 0.25), y: 0, width: view.bounds.width  * 0.25, height: view.bounds.height)
            let buttonHeight = backgroundView.bounds.width * 0.33
            SaveButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8) , y: backgroundView.center.y - (buttonHeight * 0.5), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            
            HelpButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8) , y: backgroundView.center.y + (buttonHeight * 2), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            RestartButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8), y: backgroundView.center.y + (buttonHeight * 1.0), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            
            activityButton.frame = CGRect(x: backgroundView.center.x - (buttonHeight * 0.8) , y: backgroundView.center.y - (buttonHeight * 2.5), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            
            SaveButton.layer.cornerRadius = min(SaveButton.frame.width, SaveButton.frame.height) * 0.5
            
        } else {
            backgroundView.frame = CGRect(x: 0, y: view.bounds.maxY - (view.bounds.height * 0.1), width: view.bounds.width, height: view.bounds.height * 0.1)
            let buttonWidth = backgroundView.bounds.width * 0.175
            SaveButton.frame = CGRect(x: backgroundView.center.x - (buttonWidth * 0.25), y: (buttonWidth * 0.15), width: buttonWidth * 0.5, height: buttonWidth * 0.5 )
            
            HelpButton.frame = CGRect(x: backgroundView.center.x - (buttonWidth * 2.25), y: (buttonWidth * 0.15), width: buttonWidth * 0.5, height: buttonWidth * 0.5)
            RestartButton.frame = CGRect(x: backgroundView.center.x - (buttonWidth * 1.25), y:  (buttonWidth * 0.15), width: buttonWidth * 0.5, height: buttonWidth * 0.5)
            activityButton.frame = CGRect(x: backgroundView.center.x + (buttonWidth * 1.75), y: (buttonWidth * 0.15), width: buttonWidth * 0.5, height: buttonWidth * 0.5)
        }
    }
    
    func viewsSetting(){
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        //        navAndCollectionHidding()
        imageView.frame = CGRect(x: 0, y:0, width: view.bounds.width, height: view.bounds.height * 0.9)
        imageView.backgroundColor = .clear
        croppedImageView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: imageView.bounds.height * 0.5)
        edittedImageView.frame = CGRect(x: 0, y: imageView.bounds.height * 0.5, width: view.bounds.width, height: imageView.bounds.height * 0.5)
        
        imageView.addSubview(croppedImageView)
        imageView.addSubview(edittedImageView)
        croppedImageView.contentMode = .scaleAspectFit
        edittedImageView.contentMode = .scaleAspectFit
        view.bringSubviewToFront(selectButton)
        view.bringSubviewToFront(runButton)
        view.addSubview(originalLabel)
        view.addSubview(animatedLabel)
        originalLabel.frame = CGRect(x: 0, y: view.center.y - view.bounds.width * 0.5 - view.bounds.height * 0.1, width: view.bounds.width, height: view.bounds.height * 0.1)
        animatedLabel.frame = CGRect(x: 0, y: view.center.y - view.bounds.width * 0.5 - view.bounds.height * 0.1, width: view.bounds.width, height: view.bounds.height * 0.1)
        originalLabel.text = NSLocalizedString("Original", comment: "")
        animatedLabel.text = NSLocalizedString("Resulet", comment: "")
        originalLabel.textAlignment = .center
        animatedLabel.textAlignment = .center
        originalLabel.font = .systemFont(ofSize:40,weight:.bold)
        animatedLabel.font = .systemFont(ofSize:40,weight:.bold)
        originalLabel.isHidden = true
        animatedLabel.isHidden = true
        originalLabel.adjustsFontSizeToFitWidth = true
        animatedLabel.adjustsFontSizeToFitWidth = true
        originalLabel.textColor = .white
        animatedLabel.textColor = .white
    }
}
