//
//  MyApp.swift
//  Farfor
//
//  Created by Lir-x on 25.10.16.
//  Copyright © 2016 Lir-x. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import SWXMLHash
import SDWebImage

// MARK: - Extantions

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
// MARK: - Controllers

class MenuController: UITableViewController {
    var menuItems = ["menu", "contacts"]
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = menuItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as UITableViewCell
        return cell
    }
    
}


struct Constants {
    static let customAnnotationViewIdentifier = "MyCustomAnnotation"
    static let address = ["Гаванская ул., 44, Санкт-Петербург",
                          "Наличная ул., 51, Санкт-Петербург",
                          "ул. Кораблестроителей, 30, Санкт-Петербург",
                          "ул. Кораблестроителей, 34, Санкт-Петербург"]
}


class ContactsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var geocoder: CLGeocoder!
    var coordinate: CLLocationCoordinate2D!
    @IBOutlet weak var open: UIBarButtonItem!
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        open.target = SWRevealViewController()
        open.action = #selector(SWRevealViewController.revealToggle(_:))
        mapView.delegate = self
        mapView.mapType = .hybridFlyover
        
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ContactsViewController.actionShow(sender:)))
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        for address in Constants.address {
            addAnnotation(address: address)
        }
        showAllAnnotations()
        checkCoreLocationPermission()
    }
    
    func addAnnotation(address: String)  {
        geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address){ (placemarks, error) in
            if error != nil {
            } else {
                if let placemarks =  placemarks {
                    if placemarks.count > 0 {
                        let mark = placemarks.first
                        if let coordinate = mark?.location?.coordinate {
                            let ann = CustomAnnotation(title: "test",
                                                       subtitle: address,
                                                       coordinate: coordinate)
                            self.mapView.addAnnotation(ann)

                        }
                    }
                }
            }
            
        }
    }
    func showAllAnnotations(){
        var zoomRect = MKMapRectNull
        for annotation in self.mapView.annotations {
            let center = MKMapPointForCoordinate(annotation.coordinate)
            let delta:Double = 2000
            let rect = MKMapRectMake(center.x - delta,
                                     center.y - delta,
                                     delta*2,
                                     delta*2)
            zoomRect = MKMapRectUnion(zoomRect, rect)
        }
        zoomRect = mapView.mapRectThatFits(zoomRect)

        mapView.setVisibleMapRect(zoomRect,
                                  edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                                  animated: true)
    }
        
        func showRegion(address: String) {
            geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { (placemarks, error) in
                if error != nil {
                    print (error?.localizedDescription ?? "error")
                } else {
                    if let placemarks = placemarks {
                        if placemarks.count > 0 {
                            if let center = placemarks.first?.location?.coordinate{
//
                                let span = MKCoordinateSpanMake(0.0014, 0.0014)
                                let region = MKCoordinateRegionMake(center, span)
                                
                                self.mapView.setRegion(region, animated: true)
                            }
                        }
                    }
                }
            }

    }
    
    func checkCoreLocationPermission() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
        print("restricted")
        default:
            break
        }
    }
    
    func actionShow(sender: UIBarButtonItem) {

        showAllAnnotations()
    }



    
//     MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        showAllAnnotations()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        if let location = annotation as? CustomAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.customAnnotationViewIdentifier)
            if annotationView == nil {
                annotationView = location.annotationView()
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
}


class CategoryViewController: UICollectionViewController {
    
    var menuCategories: Array<Category> = [] {
        didSet {
            DispatchQueue.main.async{
            self.collectionView?.reloadData()
            }
        }
    }
    
    @IBOutlet weak var open: UIBarButtonItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Menu"
        
        open.target = SWRevealViewController()
        open.action = #selector(SWRevealViewController.revealToggle(_:))
        
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        if let data = DataManager.sharedInstance.read() {
            updateMenu(data: data)
        }
        
        callAlamo(stringURL: "http://ufa.farfor.ru/getyml/?key=ukAXxeJYZN")
    }
    func updateMenu(data: Data) {
        print("updateMenu called")
        if let newCategoriers = Parser.sharedInstance.parse(data: data) {
            self.menuCategories = newCategoriers
        }
    }
    
    func callAlamo(stringURL: String) {
        Alamofire.request(stringURL).responseData { (response) in
            if let data = response.data {
                let manager = DataManager.sharedInstance
                if manager.read() == nil {
                    self.updateMenu(data: data)
                    manager.save(data: data)
                }
                if let oldData = manager.read() {
                
                    if oldData != data {
                        manager.save(data: data)
                        self.updateMenu(data: data)
                        let alert = UIAlertController(title: "Oops!", message:"menu updated", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay.", style: .default) { _ in })
                        self.present(alert, animated: true){}
                    
                    }
                }
            }
        }
    }
    
    
   

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.menuCategories.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCollectionViewCell
        let categoty = self.menuCategories[indexPath.row]
        for item in categoty.offers {
            if !item.picture.isEmpty {
                cell.image.sd_setImage(with: URL(string: item.picture))
                break
            }
        }
 
                cell.label.text = categoty.name.capitalized
         return cell
    }
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let offers = self.menuCategories[indexPath.row].offers
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "OfferTableViewController") as! OfferTableViewController
        controller.offers = offers
        controller.navigationItem.title = self.menuCategories[indexPath.row].name
        self.navigationController?.pushViewController(controller, animated: true)

        
    }
    
}

class OfferTableViewController: UITableViewController {
    var offers: [Offer] = []
    
    init(offers: [Offer]) {
        self.offers = offers
        super.init(style: .plain)
    }
    
    
    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        
        
    }
    override func viewDidLoad() {
        
    }
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.offers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! OfferTableViewCell
        let offer = self.offers[indexPath.row]
//        cell.offerImage = nil
        cell.offerImage.sd_setImage(with: URL(string: offer.picture))
        cell.name.text = offer.name
        cell.price.text = offer.price
        
        return cell
        
    }
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "DetailOfferViewController") as! DetailOfferViewController
        controller.offer = offers[indexPath.row]
        controller.navigationItem.title = controller.offer.name

        self.navigationController?.pushViewController(controller, animated: true)

        
    }
}
class DetailOfferViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var price: UILabel!

    var offer : Offer!
    
    override func viewDidLoad() {
        
        imageView.sd_setImage(with: URL(string: offer.picture))
        desc.text = offer.description
        price.text = offer.price



        
            }
}

// MARK: - MyCollectionViewCell

class MyCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var image: UIImageView!
}
class OfferTableViewCell: UITableViewCell {
    
    @IBOutlet weak var offerImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var price: UILabel!
    
}
// MARK: - CustomAnnotation

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    var title: String?
    
    var subtitle: String?
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    func annotationView() -> MKAnnotationView {
        
        let annotationView = MKAnnotationView(annotation: self, reuseIdentifier: Constants.customAnnotationViewIdentifier)
        annotationView.isEnabled = true
        annotationView.canShowCallout = true
        annotationView.image = UIImage(named: "placemark")
        return annotationView
    }
    
}

// MARK: - Models

class Category {
    let name: String
    let categoryID: String
    let offers:Array<Offer>
    
    init(name: String, categoryID: String, offers:Array<Offer> ) {
        self.name = name
        self.categoryID = categoryID
        self.offers = offers
    }
}
class Offer {
    let offerID: String
    let name: String
    let description: String
    let picture: String
    let categoryId: String
    let price: String
    
    init(offerID: String,
         name: String,
         description: String,
         price: String,
         picture: String,
         categoryID: String)
    {
        self.offerID = offerID
        self.name = name
        self.description = description
        self.picture = picture
        self.categoryId = categoryID
        self.price = price
    }
}

class DataManager {
    
    static let sharedInstance : DataManager = {
        let instance = DataManager()
        return instance
    }()
    
    let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("data.xml")
    
    func save(data: Data) {
        do {
            try data.write(to: self.filePath, options: .atomicWrite)
        } catch {
            print("data no saved!!!!!!!!!!!!!!")
        }
    }
    
    func read() -> Data? {
        do {
            let data = try Data(contentsOf: self.filePath)
            return data
        } catch {
            return nil
        }
    }
}

class Parser {
    
    static let sharedInstance: Parser = {
        let instance = Parser()
        return instance
    }()
    func parse(data: Data) -> [Category]? {
        let xml = SWXMLHash.parse(data)
        
        let shop = xml["yml_catalog"]["shop"]
        let offers = shop["offers"]["offer"].all
        
        var offArray:Array<Offer> = []
        
        for off in offers {
            guard let offerID = off.element?.attribute(by: "id")?.text else {
                print ("error in xml offer id")
                return nil
            }
            guard let offName = off["name"].element?.text else {
                print ("error in xml offer name")
                return nil
            }
            guard let price = off["price"].element?.text else {
                print("error in xml offer price")
                return nil
            }
            guard let description = off["description"].element?.text else {
                print("error in xml description ")
                return nil
            }
            guard let picture = off["picture"].element?.text else {
                print("error in xml picture")
                return nil
            }
            guard let categoryID = off["categoryId"].element?.text else {
                print("error in xml categoryID")
                return nil
            }
            let offer = Offer(offerID: offerID,
                              name: offName,
                              description: description,
                              price: price,
                              picture: picture,
                              categoryID: categoryID)
            offArray.append(offer)
        }
        
        let categories = shop["categories"]["category"].all
        
        var resultArray: [Category] = []
        
        for item in categories {
            
            guard let name = item.element?.text else {
                print("error in xml cat name")
                return nil
            }
            guard let categoryID = item.element?.attribute(by: "id")?.text else {
                print("error in xml cat id")
                return nil
            }
            var temp:Array<Offer> = []
            for off in offArray {
                if off.categoryId == categoryID {
                    temp.append(off)
                }
            }
            resultArray.append(Category(name: name,
                                        categoryID: categoryID,
                                        offers: temp))
        }
     return resultArray
    }
    
}
