//
//  LocationMomentViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-18.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
import MapKit

open class LocationMomentViewController: UIViewController, MomentModule {
    var mapPoint: MKAnnotation?
    var mapPolygon:  MKPolygon?

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var btnGetDirections: UIButton!

    fileprivate var emptyView: ImagedEmptyView?
    open var moment:Moment!
    fileprivate var data: PointOfInterestMomentLocalizedData?
    fileprivate var otherInfo: AnyObject?
    fileprivate lazy var localizationButton:UIBarButtonItem = UIBarButtonItem(title: "Lang", style: UIBarButtonItemStyle.plain, target: self, action: #selector(LocationMomentViewController.changeLocalization(_:)))

    open override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = nil
        subtitleLabel.text = nil
        btnGetDirections.isEnabled = false

        self.title = moment?.name.value
        
        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        guard let moment = moment else { return }

        // Do any additional setup after loading the view.
        _ = moment.validate { (success, error) in
            if success {
                _ = LocationMomentRequest.getLocations(moment: self.moment, allLocales: true) { (result, error) in
                    OperationQueue.main.addOperation {
                        self.data = result
                        if let locs = self.data?.locations[CurrentLocaleCode.uppercased()] {
                            self.localizationButton.title = CurrentLocaleCode.uppercased()
                            self.display(locs.locations.first)

                            //don't display localization switcher button if there is only 1 item
                            self.navigationItem.rightBarButtonItem = self.data!.locations.count > 1 ? self.localizationButton : nil
                        } else {
                            self.displayEmpty()
                        }
                        dimmedLoadingView.removeFromSuperview()
                    }
                }.execute()
            } else {
                OperationQueue.main.addOperation {
                    dimmedLoadingView.removeFromSuperview()
                    let alert = UIAlertController.cancellableAlertConroller("Unable to validate the moment", message: error?.localizedDescription, handler: nil)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    fileprivate func displayEmpty() {
        emptyView = ImagedEmptyView(frame: self.view.bounds)
        emptyView?.updateLabel("No point of interests available")
        self.view.addSubview(emptyView!)
    }

    open func display(_ data:PointOfInterestMomentData.LocationData?) {

        guard let data = data else {
            displayEmpty()
            return
        }

        emptyView?.removeFromSuperview()

        if let point = mapPoint {
            mapView.removeAnnotation(point)
        }
        if let polygon = mapPolygon {
            mapView.remove(polygon)
        }

        self.titleLabel.text = data.title
        self.subtitleLabel.text = data.summary
        btnGetDirections.isEnabled = true

        if data.displayPoint && data.point != nil {
            let anon = MKPointAnnotation()
            anon.title = data.title ?? data.summary ?? nil
            anon.coordinate = data.point!.coordinate
            self.mapView.addAnnotation(anon)
            self.mapPoint = anon
            self.mapView.centerCoordinate = anon.coordinate
            self.mapView.camera.altitude = 100
        }

        if data.displayPolygon && data.polygon != nil {
            let shape = data.polygon!.points.flatMap({ $0.coordinate })
            let poly = MKPolygon(coordinates: UnsafeMutablePointer(mutating: shape), count: shape.count)
            self.mapView.add(poly)
            self.mapPolygon = poly
            self.mapView.setRegion(MKCoordinateRegionForMapRect(poly.boundingMapRect), animated: true)
        }
    }

    open func changeLocalization(_ sender: UIBarButtonItem) {

        guard let items = data?.locations else {
            let controller = UIAlertController(title: "Not available", message: "No other localization is available", preferredStyle: UIAlertControllerStyle.alert)
            controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
                controller.dismiss(animated: true, completion: nil)
            }))
            present(controller, animated: true, completion: nil)
            return
        }

        let controller = UIAlertController(title: "Localized page in", message: nil, preferredStyle: UIAlertControllerStyle.alert)

        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            controller.dismiss(animated: true, completion: nil)
        }))

        for x in items {
            controller.addAction(UIAlertAction(title: x.0.uppercased(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.display(x.1.locations.first)
                self.localizationButton.title = action.title?.uppercased()
            }))
        }
        present(controller, animated: true, completion: nil)
    }

    @IBAction func getDirectionsButtonTapped(_ sender: AnyObject) {
        var didOpen = false
        if let title = self.localizationButton.title, let item = self.data?.locations[title], let coordinate = item.locations.first?.coordinate {
            let launchOptions:[String:AnyObject] = [
                    MKLaunchOptionsMapTypeKey : NSNumber(value: MKMapType.standard.rawValue as UInt),
                    MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving as AnyObject
            ]
            
            let placeMark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placeMark)
            mapItem.name = item.locations.first?.title
            
            didOpen = MKMapItem.openMaps(with: [mapItem], launchOptions: launchOptions)
        }
        
        if !didOpen {
            let vc = UIAlertController.cancellableAlertConroller(nil, message: "Direction unavailable", handler: nil)
            present(vc, animated: true, completion: nil)
        }
    }

    open func initialize(_ moment:Moment) {
        self.moment = moment
    }

    open func load(_ moment:Moment, info:AnyObject?) {
        load(moment, info: info, completion: nil)
    }

    open func load(_ moment:Moment, info:AnyObject?, completion:((_ data:Data?, _ error:NSError?, _ otherInfo:NSDictionary?)->Void)?) {
        self.moment = moment
    }

    open func unload(_ moment:Moment) { }


    // MARK: - Moment Data

    open class PointOfInterestMomentLocalizedData : NSObject, ResponseObjectSerializable {

        open var locations:[String:PointOfInterestMomentData] = [:]

        public required init?(response: HTTPURLResponse, representation: AnyObject) {
            super.init()
            if let dictionary = representation as? [String: NSDictionary] {
                for (locale, itemDictionary) in dictionary {
                    if let item = PointOfInterestMomentData(dictionary: itemDictionary) {
                        self.locations[locale.uppercased()] = item
                    }
                }

            } else {
                return nil
            }
        }
    }

    open class PointOfInterestMomentData : NSObject, ResponseObjectSerializable {

        open class LocationData : NSObject {
            open var id: Int!
            open var title: String?
            open var summary: String?
            open var displayPoint: Bool = false
            open var displayPolygon: Bool = false
            open var point: Point?
            open var polygon: Polygon?


            open var coordinate: CLLocationCoordinate2D? {

                if let point = point , displayPoint {
                    return CLLocationCoordinate2D(latitude: CLLocationDegrees(point.latitude), longitude: CLLocationDegrees(point.longitude))
                } else if let point = polygon?.centroid , displayPolygon {
                    return CLLocationCoordinate2D(latitude: CLLocationDegrees(point.latitude), longitude: CLLocationDegrees(point.longitude))
                } else {
                    return nil
                }
            }

            init?(dictionary: NSDictionary) {

                id = (dictionary.value(forKey: "id") as? NSNumber)?.intValue ?? -1
                title = dictionary.htmlDecodedString("title")
                summary = dictionary.htmlDecodedString("description")
                displayPoint = (dictionary.value(forKey: "displayPoint") as? NSNumber)?.boolValue ?? false
                displayPolygon = (dictionary.value(forKey: "displayPolygon") as? NSNumber)?.boolValue ?? false

                if let p = dictionary.value(forKey: "point") as? NSDictionary, let pp = Point(dictionary: p) {
                    point = pp
                }

                if let poly = dictionary.value(forKey: "polygon") as? NSDictionary, let ppoly = Polygon(dictionary: poly) {
                    polygon = ppoly
                }
            }
        }

        public struct Point {
            public var id : Int!
            public var latitude: Float
            public var longitude: Float
            public var altitude: Float = 0.0

            public var coordinate: CLLocationCoordinate2D {
                return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            }

            public var valid: Bool {
                return abs(latitude) <= 90.0 && abs(longitude) <= 180.0
            }

            init?(dictionary:NSDictionary) {
                id = (dictionary.value(forKey: "id") as? NSNumber)?.intValue ?? -1
                latitude = (dictionary.value(forKey: "latitude") as? NSNumber)?.floatValue ?? 128
                longitude = (dictionary.value(forKey: "longitude") as? NSNumber)?.floatValue ?? 256
                altitude = (dictionary.value(forKey: "altitude") as? NSNumber)?.floatValue ?? 0.0
            }
        }

        public struct Polygon {
            public var centroid: Point!
            public var points: [Point] = []
            public var id: Int!

            init?(dictionary:NSDictionary) {
                id = (dictionary.value(forKey: "id") as? NSNumber)?.intValue ?? -1

                if let centroidDict = dictionary.value(forKey: "centroid") as? NSDictionary, let c = Point(dictionary: centroidDict) {
                    centroid = c
                }

                if let pointsArr = dictionary.value(forKey: "points") as? [NSDictionary]{
                    for x in pointsArr {
                        if let c = Point(dictionary: x) {
                            points.append(c)
                        }
                    }
                }
            }
        }

        open var locations:[LocationData] = []
        open var id: Int!

        public required init?(response: HTTPURLResponse, representation: AnyObject) {
            super.init()
            guard let dictionary = representation as? [String: AnyObject] else {
                return nil
            }
            if readFromDictionary(dictionary as NSDictionary) == false {
                return nil
            }
        }

        init?(dictionary: NSDictionary) {
            super.init()
            guard let dictionary = dictionary as? [String: AnyObject] else {
                return nil
            }
            if readFromDictionary(dictionary as NSDictionary) == false {
                return nil
            }
        }

        fileprivate func readFromDictionary(_ dictionary: NSDictionary) -> Bool {
            guard let locations = dictionary["locations"] as? [NSDictionary] , locations.count > 0 else {
                return false
            }
            for x in locations {
                if let item = LocationData(dictionary: x) {
                    self.locations.append(item)
                }
            }
            self.id = dictionary["id"] as? Int ?? -1
            return true
        }
    }
}


extension LocationMomentViewController : MKMapViewDelegate {

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = MKPinAnnotationView()
        pinView.canShowCallout = true
        pinView.animatesDrop = true
        if #available(iOS 9.0, *) {
            pinView.pinTintColor = UIColor.red
        } else {
            pinView.pinColor = .red
        }
        return pinView
    }

    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
        renderer.fillColor = UIColor.gray.withAlphaComponent(0.1)
        renderer.strokeColor = UIColor.cyan.withAlphaComponent(0.5)
        renderer.lineWidth = 2.0
        return renderer

    }

}

enum LocationMomentRequest : Requestable {

    // --- cases
    case getLocations(moment: Moment, allLocales: Bool, completion: (_ data: LocationMomentViewController.PointOfInterestMomentLocalizedData?, _ error: NSError?) -> Void)
    case getLocation(moment: Moment, locationID: Int, completion: (_ data: LocationMomentViewController.PointOfInterestMomentData?, _ error: NSError?) -> Void)

    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }

    var baseURI: String {
        switch self {
        case let .getLocations(moment, allLocales, _):
            return moment.launchURL + "/locationbits" + (allLocales ? "?alllocales=true" : "")
        case let .getLocation(moment, locationID, _):
            return moment.launchURL + "/locationbits/\(locationID)"
        }
    }

    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getLocations(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: LocationMomentViewController.PointOfInterestMomentLocalizedData?, error) -> Void in
                completion(data, error)
            }
        case .getLocation(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: LocationMomentViewController.PointOfInterestMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}

