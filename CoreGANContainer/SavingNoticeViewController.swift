//
//  SavingNoticeViewController.swift
//  SegmentCamera
//
//  Created by 間嶋大輔 on 2020/03/05.
//  Copyright © 2020 daisuke. All rights reserved.
//

import UIKit
import StoreKit


class SavingNoticeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        view.layer.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1957558474)
        var noticeWidth = CGFloat.zero
        if view.bounds.width < view.bounds.height {
            noticeWidth = view.bounds.width - 40
        } else {
            noticeWidth = view.bounds.height - 40
        }
        NoticeView.frame = CGRect(x: view.center.x - (noticeWidth * 0.5), y: 20, width: noticeWidth, height: noticeWidth)
        NoticeLabel.frame = CGRect(x: 10, y: 0, width: noticeWidth, height: noticeWidth * 0.2)
        editedImageView.frame = CGRect(x: 20, y: NoticeLabel.frame.maxY, width: noticeWidth - 30, height: NoticeView.bounds.height - noticeWidth * 0.2 - NoticeLabel.frame.height)
        OKLabel.frame = CGRect(x: 0, y: noticeWidth * 0.8, width: noticeWidth, height: noticeWidth * 0.2)
        view.addSubview(NoticeView)
        NoticeView.addSubview(NoticeLabel)
        NoticeView.addSubview(OKLabel)
        NoticeView.addSubview(editedImageView)
        NoticeView.backgroundColor = .white
        NoticeLabel.text = NSLocalizedString(NSLocalizedString("Saved in photo library", comment: ""), comment: "")
        OKLabel.text =  NSLocalizedString("OK", comment: "")
        NoticeLabel.textAlignment = .center
        OKLabel.textAlignment = .center
        NoticeLabel.adjustsFontSizeToFitWidth = true
        OKLabel.adjustsFontSizeToFitWidth = true
        OKLabel.backgroundColor = .systemOrange
        OKLabel.textColor = .white
        NoticeLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        OKLabel.font = .systemFont(ofSize: 20, weight: .heavy)
        NoticeView.layer.cornerRadius = 10
        NoticeView.clipsToBounds = true
        editedImageView.contentMode = .scaleAspectFit
        let okTap = UITapGestureRecognizer(target: self, action: #selector(OKButton))
        OKLabel.addGestureRecognizer(okTap)
        OKLabel.isUserInteractionEnabled = true
    }
    var NoticeView = UIView()
    var NoticeLabel = UILabel()
    var OKLabel = UILabel()
    
    var editedImageView = UIImageView()
    var editedImage:UIImage? {
        didSet {
            editedImageView.image = editedImage
        }
    }

        @objc func OKButton() {
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
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

           var tapLocation: CGPoint = CGPoint()
           let touch = touches.first
           tapLocation = touch!.location(in: self.view)

           if !NoticeView.frame.contains(tapLocation) {
               self.dismiss(animated: false, completion: nil)
           }
       }
    
    override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
