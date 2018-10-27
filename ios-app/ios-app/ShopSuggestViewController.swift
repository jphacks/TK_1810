//
//  ShopSuggestViewController.swift
//  ios-app
//
//  Created by 三上大河 on 2018/10/27.
//  Copyright © 2018年 三上大河. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire

class ShopSuggestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var shopLists:[String] = []
    var searchResults: [String] = []
    var image: UIImage?
    
    let locationManager = CLLocationManager()
    var latitude: CLLocationDegrees = 0.0
    var longitude: CLLocationDegrees = 0.0
    var selectedShopName: String = ""
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getShopsFromLocation(lat: String(35.64808), lng: String(139.741614))
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        locationManager.delegate = self
        if searchBar.resignFirstResponder() {
            tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.searchResults = self.shopLists
        self.tableView.reloadData()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.resignFirstResponder()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.last?.coordinate {
            mapView.userTrackingMode = MKUserTrackingMode.follow
            mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
            // 現在地を拡大して表示する
            let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            mapView.region = region
        }
        let location = locations.first
        let lat = location?.coordinate.latitude
        let lng = location?.coordinate.longitude
        print("lat: \(lat), lng: \(lng)")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
        let shopNameLabel = cell.viewWithTag(1) as! UILabel
        shopNameLabel.text = "\(searchResults[indexPath.row])"
        //        cell.textLabel!.text = "\(searchResults[indexPath.row])"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    // Cellが選択された場合
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedShopName = "\(searchResults[indexPath.row])"
        let userDefaults = UserDefaults.standard
        if selectedShopName != "" {
            userDefaults.set(selectedShopName, forKey: "SelectedShop")
            userDefaults.synchronize()
            // SubViewController へ遷移するために Segue を呼び出す
            performSegue(withIdentifier: "selectedShop",sender: nil)
        }
    }
    
    // ここ変える
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "selectedShop") {
            let postImageVC: PostImageViewController = (segue.destination as? PostImageViewController)!
            // SubViewController のselectedImgに選択された画像を設定する
            postImageVC.image = self.image
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchResults = self.shopLists
        self.tableView.reloadData()
        print(self.searchResults)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // リストを全消去する
        self.searchResults.removeAll()
        
        // 検索文字列を生成する
        let searchText = searchBar.text!
        
        if searchText == "" {
            self.searchResults = self.shopLists
        } else {
            // 検索対象の文字列を絞り込んで、リストにする
            self.searchResults = self.shopLists.filter{
                // 大文字と小文字を区別せずに検索
                $0.lowercased().contains(searchText.lowercased())
            }
        }
        self.tableView.reloadData()
    }
    
    func getShopsFromLocation(lat: String, lng: String) {
        //        let url = "https://mutekikantai-backend.herokuapp.com/shops/search?lat=\(lat)&long=\(lng)"
        let url = "https://mutekikantai-backend.herokuapp.com/shops"
        let jsonDecoder = JSONDecoder()
        
        Alamofire.request(url).validate().responseJSON { res in
            switch res.result {
            case .success:
                let resObj = try! jsonDecoder.decode(Response.self, from: (res.data)!)
                let shops = try! jsonDecoder.decode([Shop].self, from: (resObj.data["shops"]?.rawData())!)
                print(shops)
                for shop in shops {
                    self.shopLists.append(shop.name)
                    
                }
                self.searchResults = self.shopLists
            case .failure(let error):
                print(error)
            }
        }
    }
}
