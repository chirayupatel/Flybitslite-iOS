//
//  FlybitsExtension.swift
//  Flybits
//
//  Created by chu on 2015-09-03.
//  Copyright © 2015 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK
import MapKit


extension Zone {

    func lite_favourite(_ favourite:Bool, completion:@escaping (_ success:Bool, _ error:NSError?)->Void) {
        _ = ZoneRequest.favourite(identifier: self.identifier, favourite: favourite) { (zoneID, success, error) -> Void in
            if Utils.ErrorChecker.isAccessDenied(error) {
                Utils.UI.takeUserToLoginPage()
                return
            }

            if success {
                
                let query = ZonesQuery(limit: 1, offset: 0)
                query.zoneIDs = [self.identifier]
                query.includes = [ZonesQueryConstants.Analytics, ZonesQueryConstants.ID, ZonesQueryConstants.ActiveUserRelationship]
                
                _ = ZoneRequest.query(query) { (zones, pagination, error) -> Void in
                    if Utils.ErrorChecker.isAccessDenied(error) {
                        Utils.UI.takeUserToLoginPage()
                        return
                    }

                    OperationQueue.main.addOperation {
                        if let newZoneValue = zones.first {
                            self.favourited = newZoneValue.favourited
                            _ = self.update(from: [ZonesQueryConstants.Analytics : ["favoriteCount" : newZoneValue.favouriteCount]])
                        }
                        completion(success, error)
                    }
                }.execute()
            }
        }.execute()
    }


    func lite_share() -> UIActivityViewController {
        let shareURLString = AppConstants.ZoneShareURL(self)
        let shareURL = URL(string: shareURLString)!

        let item = ZoneShareItemURLSource(URL: shareURL, subject: "Checkout this cool zone!", image: UIImage(named: "ic_logo")!)

        let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        return activity

    }

    func lite_openExternalMap(_ completion:@escaping (_ success:Bool)->Void) {


//        let currentLocationItem = MKMapItem.mapItemForCurrentLocation()

        let launchOptions: [String:AnyObject]? = [
            MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving as AnyObject,
            MKLaunchOptionsMapSpanKey : NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)),
            MKLaunchOptionsMapTypeKey: NSNumber.init(value: MKMapType.standard.rawValue),
        ]

        if CLLocationCoordinate2DIsValid(self.addressCoordinate) {
            let coordinates = self.addressCoordinate
            let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates, addressDictionary: nil))
            destination.name = name.value
            MKMapItem.openMaps(with: [destination], launchOptions:launchOptions)
            completion(true)
        } else if let zoneAddress = self.address , !zoneAddress.isEmpty {
            CLGeocoder().geocodeAddressString(zoneAddress, completionHandler: { (placemarks, error) -> Void in
                if let currentItem = placemarks?.first {
                    
                    let destination = MKMapItem(placemark:MKPlacemark(placemark: currentItem))
                    destination.name = self.name.value
                    MKMapItem.openMaps(with: [destination], launchOptions: launchOptions)
                    completion(true)
                } else {
                    completion(false)
                }
            })
        } else if let anyPoint = self.shapes?.first {
            let destination = MKMapItem(placemark: MKPlacemark(coordinate: anyPoint.coordinate, addressDictionary: nil))
            destination.name = name.value
            MKMapItem.openMaps(with: [destination], launchOptions:launchOptions)
            completion(true)
        } else {
            completion(false)
        }
    }
}

extension Moment {
    public func validate(_ completion: @escaping (_ success: Bool, _ error: NSError?) -> Void) -> FlybitsRequest {
        return MomentRequest.autoValidate(moment: self) { (validated, error) -> Void in
            OperationQueue.main.addOperation {
                if Utils.ErrorChecker.isAccessDenied(error) {
                    Utils.UI.takeUserToLoginPage()
                    return
                }
                completion(validated, error)
            }
        }.execute()
    }
}


extension FlybitsSDK.Query {
    public func nextPage() -> Self {
        let query = self
        query.pager = Pager(limit: query.pager.limit, offset: query.pager.offset + query.pager.limit, countRecords: 0)
        return query
    }
}

protocol PushCapable {
    var pushRoute: String { get }
}

extension Moment : PushCapable {
    var pushRoute: String {
        return "zoneMomentInstance/\(identifier)"
    }
}

extension Zone : PushCapable {
    var pushRoute: String {
        return "zone/\(identifier)"
    }
}
