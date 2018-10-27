//
//  ShowCouponScoreViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/28.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit

class ShowCouponScoreViewController: UIViewController {

    var image: UIImage?
    var availableFrom: String = ""
    var expiredAt: String = ""
    var shopName: String = ""
    var amount: Int = 0
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var discountValue: UILabel!
    @IBOutlet var availableDate: UILabel!
    @IBOutlet var expiredDate: UILabel!
    @IBOutlet var shopNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.image = image
        self.discountValue.text = String(amount) + "円割引"
        self.availableDate.text = "利用開始日：" + availableFrom
        self.expiredDate.text = "有効期限：" + expiredAt
        self.shopNameLabel.text = "お店名：" + shopName
        
    }
}
