//
//  CurrentUserViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit
import Alamofire
import SDWebImage
import Swifter

class CurrentUserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    
    @IBOutlet var profileImageView: UIImageView!
    var access_token: String = ""
    var access_secret: String = ""
    var selectedCouponID: Int = 0
    
    var coupons = [Coupon]()
    var shops = [Shop]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadShops()
        getCurrentUser()
        getCoupons()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coupons.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let couponImageView = cell.viewWithTag(1) as! UIImageView
        let couponImageURL = URL(string: self.coupons[indexPath.row].photo_url as String)!
        couponImageView.sd_setImage(with: couponImageURL, completed: nil)
        couponImageView.clipsToBounds = true
        
        let shopNameLable = cell.viewWithTag(2) as! UILabel
        let shop = self.shops.filter { $0.id == self.coupons[indexPath.row].shop_id }
        let shopName = shop.first!.name
        shopNameLable.text = shopName
        
        let amountLable = cell.viewWithTag(3) as! UILabel
        amountLable.text = "割引金額：" + String(self.coupons[indexPath.row].amount) + "円"
        
        let postedDateLable = cell.viewWithTag(4) as! UILabel
        postedDateLable.text = "有効：" + self.coupons[indexPath.row].expired_at
        
        let status = cell.viewWithTag(5) as! UILabel
        status.layer.cornerRadius = 10
        if self.coupons[indexPath.row].is_used {
            status.text = "利用済み"
            status.backgroundColor = UIColor.red
        } else {
            status.text = "利用可能"
            status.backgroundColor = UIColor.green
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 312
    }
    
    
    func getCoupons() {
        let url = "https://mutekikantai-backend.herokuapp.com/users/current/coupons"
        //        let url = "http://127.0.0.1:3000/users/current/coupons"
        let jsonDecoder = JSONDecoder()
        
        Alamofire.request(url).validate().responseJSON { res in
            
            switch res.result {
            case .success:
                let resObj = try! jsonDecoder.decode(Response.self, from: (res.data)!) // NSData
                print(resObj)
                self.coupons = try! jsonDecoder.decode([Coupon].self, from: (resObj.data["coupons"]?.rawData())!)
                print(self.coupons)
                UserDefaults.standard.set(try! resObj.data["coupons"]?.rawData(), forKey: "Coupons")
            case .failure(let error):
                print(error)
            }
            self.tableView.reloadData()
        }
    }
    
    func getCurrentUser() {
        let url = "https://mutekikantai-backend.herokuapp.com/users/current"
        //        let url = "http://127.0.0.1:3000/users/current"
        let jsonDecoder = JSONDecoder()
        
        Alamofire.request(url).validate().responseJSON { res in
            
            switch res.result {
            case .success:
                let resObj = try! jsonDecoder.decode(Response.self, from: (res.data)!) // NSData
                let user = try! jsonDecoder.decode(User.self, from: (resObj.data["user"]?.rawData())!)
                print(user.twitter_name)
                let profileImageURL = URL(string: user.image_url)
                self.profileImageView!.sd_setImage(with:  profileImageURL, completed: nil)
                self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width * 0.5
                self.profileImageView.clipsToBounds = true
                UserDefaults.standard.set(user.access_token, forKey: "AccessToken")
                UserDefaults.standard.set(user.access_secret, forKey: "AccessSecret")
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func loadShops() {
        let jsonDecoder = JSONDecoder()
        self.shops = try! jsonDecoder.decode([Shop].self, from: (UserDefaults.standard.data(forKey: "Shops"))!)
    }
}
