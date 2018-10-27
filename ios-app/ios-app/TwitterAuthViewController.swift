//
//  TwitterAuthViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit
import SwiftyJSON

class TwitterAuthViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView: UIWebView!
    var session_id: String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        
        let url = URL(string: "https://mutekikantai-backend.herokuapp.com/auth/twitter")
        //        let url = URL(string: "http://127.0.0.1:3000/auth/twitter")
        let urlRequest = URLRequest(url: url!)
        webView.loadRequest(urlRequest)
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        // インディケーター開始
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // インディケーター終了
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        let requestedUrl = self.webView.request?.url!.absoluteString
        if requestedUrl!.contains("/auth/twitter/callback") {
            self.performSegue(withIdentifier: "toTimeLine", sender: nil)
        }
    }
    
}

