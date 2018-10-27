
//
//  PostImageViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit
import Swifter
import Alamofire

class PostImageViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var image: UIImage?
    var access_token: String = ""
    var access_secret: String = ""
    var shopName: String = ""
    var foodLists:[String] = [""]
    var shopID: Int = 0
    var foodID: Int = 0
    var shops = [Shop]()
    var foodcategories = [Foodcategory]()
    //    var insta_score = InstaScore()
    var tweetComment: String = ""
    var couponAmount: Int = 0
    var couponExpeiredAt: String = ""
    var couponAvailableFrom: String = ""
    var couponShopID: Int = 0
    
    @IBOutlet var postImageView: UIImageView!
    @IBOutlet var shopNameButton: UIButton!
    @IBOutlet var foodName: UITextField!
    @IBOutlet var caption: UITextView!
    
    var pickerView: UIPickerView = UIPickerView()
    //    let list = ["オムライス", "ラーメン"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        access_token = UserDefaults.standard.string(forKey: "AccessToken")!
        access_secret = UserDefaults.standard.string(forKey: "AccessSecret")!
        loadShops()
        loadFoodcategories()
        caption.delegate = self
        foodName.delegate = self
        postImageView.image = self.image
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.showsSelectionIndicator = true
        
        let toolbar = UIToolbar(frame: CGRectMake(0, 0, 0, 35))
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(PostImageViewController.done))
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(PostImageViewController.cancel))
        toolbar.setItems([cancelItem, doneItem], animated: true)
        
        self.foodName.inputView = pickerView
        self.foodName.inputAccessoryView = toolbar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: ["SelectedShop": "お店を選択"])
        self.shopName = userDefaults.object(forKey: "SelectedShop") as! String
        if shopName != "" {
            shopNameButton.setTitle(shopName, for: .normal)
        }
    }
    
    @IBAction func postSNS(_ sender: Any) {
        let swifter = Swifter(consumerKey: TwitterToken().consumerKey, consumerSecret: TwitterToken().consumerSecret, oauthToken: self.access_token, oauthTokenSecret: self.access_secret)
        let postImage = self.image
        print(image as Any)
        let imageData = postImage!.jpegData(compressionQuality: 0.1)
        self.tweetComment = "#ばえるーポン" + " #" + self.shopName + "\n" + caption.text //+ "\n #jphacks" //本番はコメントを取る
        swifter.postTweet(status: tweetComment, media: imageData!, success: { res in
            print(res)
            let media_url = res["extended_entities"]["media"][0]["media_url"].string
            let tweet_url = res["extended_entities"]["media"][0]["expanded_url"].string
            print(media_url as Any)
            self.postAI(photo_url: media_url!, tweet_url: tweet_url!)
        }, failure: { error in
            print(error)
        })
    }
    
    func postAI(photo_url: String, tweet_url: String) {
        let url = MLEndPoint().url
        let jsonDecoder = JSONDecoder()
        let parameters:[String: Any] = [
            "image_url": photo_url
        ]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { res in
            switch res.result {
            case .success:
                let resObj = try! jsonDecoder.decode(ResponseAI.self, from: (res.data)!) // NSData
                print(resObj)
                let insta_score = try! jsonDecoder.decode(InstaScore.self, from: resObj.data.rawData())
                self.postBackend(photo_url: photo_url, tweet_url: tweet_url, insta_score: insta_score.score)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func postBackend(photo_url: String, tweet_url: String, insta_score: Float) {
        for shop in shops {
            if shop.name == shopNameButton.currentTitle {
                self.shopID = shop.id
            }
        }
        
        for food in foodcategories {
            if food.name == foodName.text {
                self.foodID = food.id
            }
        }
        let url = "https://mutekikantai-backend.herokuapp.com/coupons"
        //        let url = "http://127.0.0.1:3000/coupons"
        let jsonDecoder = JSONDecoder()
        let parameters:[String: Any] = [
            "insta_score": insta_score,
            "photo_url": photo_url,
            "comment": "hoge",
            "tweet_url": tweet_url,
            "shop_id": self.shopID,
            "food_category_id": self.foodID
        ]
        Alamofire.request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { res in
            switch res.result {
            case .success:
                let resObj = try! jsonDecoder.decode(Response.self, from: (res.data)!) // NSData
                print(resObj)
                let coupon = try! jsonDecoder.decode(Coupon.self, from: (resObj.data["coupon"]?.rawData())!)
                self.couponAmount = coupon.amount
                self.couponExpeiredAt = coupon.expired_at
                self.couponAvailableFrom = coupon.available_from
                self.performSegue(withIdentifier: "showCoupon", sender: nil)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectShop" {
            let shopSuggestVC = segue.destination as! ShopSuggestViewController
            shopSuggestVC.image = self.postImageView.image
        }
    }
    
    func loadShops() {
        let jsonDecoder = JSONDecoder()
        self.shops = try! jsonDecoder.decode([Shop].self, from: (UserDefaults.standard.data(forKey: "Shops"))!)
    }
    
    func loadFoodcategories() {
        let jsonDecoder = JSONDecoder()
        self.foodcategories = try! jsonDecoder.decode([Foodcategory].self, from: (UserDefaults.standard.data(forKey: "FoodCategories"))!)
        for food in foodcategories {
            self.foodLists.append(food.name)
        }
    }
    
    // PickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return foodLists.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return foodLists[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.foodName.text = foodLists[row]
    }
    
    @objc func cancel() {
        self.foodName.text = ""
        self.foodName.endEditing(true)
    }
    
    @objc func done() {
        self.foodName.endEditing(true)
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
