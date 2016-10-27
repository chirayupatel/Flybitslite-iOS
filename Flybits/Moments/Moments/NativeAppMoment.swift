//
//  NativeAppMoment.swift
//  Flybits
//
//  Created by Archuthan Vijayaratnam on 1/6/16.
//  Copyright © 2016 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

final class NativeAppMoment: NSObject, MomentModule {
    override required init() {
        super.init()
    }

    var moment:Moment!
    fileprivate var data: [NativeAppMomentData]?
    fileprivate var otherInfo: AnyObject?

    func initialize(_ moment:Moment) {
        self.moment = moment
    }

    func load(_ moment:Moment, info:AnyObject?) {
        load(moment, info: info, completion: nil)
    }

    func load(_ moment:Moment, info:AnyObject?, completion:((_ data:Data?, _ error:NSError?, _ otherInfo:NSDictionary?)->Void)?) {
        self.moment = moment
        self.otherInfo = info
        _ = self.moment.validate { (success, error) -> Void in

            guard let completion = completion else {
                return
            }
            guard success && error == nil else {
                let controller = UIAlertController.cancellableAlertConroller("Unable to load", message: error?.localizedDescription, handler: nil)
                completion(nil, error, [ "viewController":controller])
                return
            }

            _ = NativeAppMomentRequest.getData(moment: self.moment) { (data, error) -> Void in
                OperationQueue.main.addOperation {
                    if let iTunesURL = data?.items.first?.iTunesURL, let appURL = NSURL(string: iTunesURL) {
                        if UIApplication.shared.canOpenURL(appURL as URL) {
                            UIApplication.shared.openURL(appURL as URL)
                            completion(nil, error, ["FlybitsReturnStatus":"success"]) // that we have successfully handled this request
                        } else {
                            let alert = UIAlertController.cancellableAlertConroller("Not supported", message: "Unable to open native app", handler:nil)
                            completion(nil, error, ["parsed":data!, "viewController":alert])
                        }
                    } else if let error = error?.localizedDescription {
                        let alert = UIAlertController.cancellableAlertConroller("Error Occured", message: error, handler:nil)
                        completion(nil, nil, ["viewController":alert])
                    } else {
                        let alert = UIAlertController.cancellableAlertConroller(nil, message: "Not available at this time", handler:nil)
                        completion(nil, nil,  ["viewController":alert])
                    }
                }
            }.execute()
        }
    }

    func unload(_ moment: Moment) { }

    // MARK: - Moment Data
    class NativeAppMomentData : NSObject, ResponseObjectSerializable {
        // [{
        //    googlePlayUrl = "https://play.google.com/store/apps/details?id=com.facebook.katana&hl=en";
        //    iTunesUrl = "https://itunes.apple.com/us/app/idmss-lite/id517936193?mt=8";
        //    id = 3;
        //    serviceId = "6031f10e-7427-4224-a633-d044f4d704b5";
        // }]

        class NativeAppData {
            var identifier: Int
            var momentID: String
            var iTunesURL: String?
            var googlePlayURL: String?

            init?(dictionary: NSDictionary) {
                if let dictionary = dictionary as? [String: AnyObject], let momentID = dictionary["serviceId"] as? String {
                    self.identifier = dictionary["id"] as? Int ?? -1
                    self.iTunesURL = dictionary["iTunesUrl"] as? String
                    self.googlePlayURL = dictionary["googlePlayUrl"] as? String
                    self.momentID = momentID
                } else {
                    self.identifier = 0
                    self.momentID = ""
                    return nil
                }
            }

        }
        var items: [NativeAppData] = []
        required init?(response: HTTPURLResponse, representation: AnyObject) {
            if let array = representation as? [[String: AnyObject]] {
                for item in array {
                    if let data = NativeAppData(dictionary: item as NSDictionary) {
                        items.append(data)
                    }
                }
            }
        }
    }
}

enum NativeAppMomentRequest : Requestable {
    // --- cases
    case getData(moment: Moment, completion:(_ data: NativeAppMoment.NativeAppMomentData?, _ error: NSError?) -> Void)

    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }

    var baseURI: String {
        switch self {
        case let .getData(moment, _):
            return moment.launchURL + "/Apps/"
        }
    }

    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getData(_, let completion):
            let request = FlybitsRequest(urlRequest)
            _ = request.setHttpSuccessStatusCodeBound(lower: 200, upper: 202)
            return request.response { (request, response, data: NativeAppMoment.NativeAppMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}


