//
//  CouponViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit
import SDWebImage

class CouponViewController: UIViewController {
    
    @IBOutlet var photoImage: UIImageView!
    
    @IBOutlet var discountValue: UILabel!
    @IBOutlet var shopNameLabel: UILabel!
    @IBOutlet var availableFrom: UILabel!
    @IBOutlet var expiredAt: UILabel!
    @IBOutlet var shopImage: UIImageView!
    @IBOutlet var qrImage: UIImageView!
    
    var coupons = [Coupon]()
    var shops = [Shop]()
    var couponID: Int = 0
    var twitterUrl: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCoupons()
        loadShops()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        couponID = userDefaults.object(forKey: "SelectedCoupon") as! Int
        print(couponID)
        setCoupon()
    }
    
    @IBAction func backCoupons(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setCoupon() {
        for coupon in coupons {
            if coupon.id == couponID {
                
                let shop = self.shops.filter { $0.id == coupon.shop_id }
                let shopName = shop.first!.name
                shopNameLabel.text = shopName
                
                // 割引値段
                discountValue.text = String(coupon.amount) + "円割引"
                
                // QRコード生成
                let discountURL = "https://mutekikantai-backend.herokuapp.com/coupons/apply/\(coupon.uuid)"
                let discountUrlData = discountURL.data(using: String.Encoding.utf8)!
                let qr = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": discountUrlData, "inputCorrectionLevel": "M"])!
                let sizeTransform = CGAffineTransform(scaleX: 10, y: 10)
                let qrImage = qr.outputImage!.transformed(by: sizeTransform)
                let context = CIContext()
                let cgImage = context.createCGImage(qrImage, from: qrImage.extent)
                let uiImage = UIImage(cgImage: cgImage!)
                self.qrImage.image = uiImage
                
                self.availableFrom.text = coupon.available_from
                self.expiredAt.text = coupon.expired_at
                self.twitterUrl = coupon.tweet_url
                
                coupon.tweet_url
                // お店画像
                let shopImageURL = URL(string: (shop.first?.image_url)!)
                self.shopImage.sd_setImage(with: shopImageURL, completed: nil)
                // 背景画像
                let couponImageURL = URL(string: coupon.photo_url
                )
                self.photoImage!.sd_setImage(with: couponImageURL
                    , completed: nil)
                self.photoImage.layer.cornerRadius = 0.5
            }
        }
    }
    
    @IBAction func twitterLink(_ sender: Any) {
        let url = URL(string: self.twitterUrl)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func loadCoupons() {
        let jsonDecoder = JSONDecoder()
        self.coupons = try! jsonDecoder.decode([Coupon].self, from: (UserDefaults.standard.data(forKey: "Coupons"))!)
    }
    
    func loadShops() {
        let jsonDecoder = JSONDecoder()
        self.shops = try! jsonDecoder.decode([Shop].self, from: (UserDefaults.standard.data(forKey: "Shops"))!)
    }
}
