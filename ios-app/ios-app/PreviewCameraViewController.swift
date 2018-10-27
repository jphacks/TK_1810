//
//  PreviewCameraViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit
import Swifter

class PreviewCameraViewController: UIViewController {
    
    var image: UIImage?
    
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
        let userDefaults = UserDefaults.standard
        userDefaults.set("お店を選択してください", forKey: "SelectedShop")
        userDefaults.synchronize()
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePhoto(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }
    
}
