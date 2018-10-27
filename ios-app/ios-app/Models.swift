//
//  Models.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import SwiftyJSON
import Default

class Response: Codable {
    let status: String
    let error: String?
    let data: Dictionary<String, JSON>
}

class Shop: Codable {
    let id:Int
    let name:String
    let url:String
    let address:String
    let latitude:Float?
    let longitude:Float?
    let mean_coupon:Int
    let image_url:String
}

class User: Codable {
    let id:Int
    let twitter_name: String
    let twitter_id: String
    let twitter_desc: String
    let image_url: String
    let access_secret: String
    let access_token: String
}

class Coupon: Codable {
    let id: Int
    let amount: Int
    let available_from: String
    let expired_at: String
    let photo_url: String
    let shop_id: Int
    let user_id: Int
    let insta_score: Float
    let is_used: Bool
    let comment: String
    let tweet_url: String
    let uuid: String
}

class Foodcategory: Codable {
    let id: Int
    let name: String
}

class ResponseAI: Codable {
    let status: String
    let error: String?
    let data: JSON
}

class InstaScore: Codable {
    let score: Float
}
