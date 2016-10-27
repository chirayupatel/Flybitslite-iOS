//
//  SpeeddialMoment.swift
//  Flybits
//
//  Created by chu on 2015-09-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

open class SpeeddialMoment: NSObject, MomentModule {

    public override required init() {
        super.init()
    }

    open var moment:Moment!
    fileprivate var data: [SpeeddialMomentData]?
    fileprivate var otherInfo: AnyObject?

    open func initialize(_ moment:Moment) {
        self.moment = moment
    }

    open func load(_ moment:Moment, info:AnyObject?) {
        load(moment, info: info, completion: nil)
    }

    open func load(_ moment:Moment, info:AnyObject?, completion:((_ data:Data?, _ error:NSError?, _ otherInfo:NSDictionary?)->Void)?) {
        self.moment = moment
        self.otherInfo = info
        _ = self.moment.validate { (success, error) -> Void in

            guard let completion = completion else {
                return
            }

            guard success else {
                let controller = UIAlertController.cancellableAlertConroller("Unable to load", message: error?.localizedDescription, handler: nil)
                completion(nil, error, [ "viewController":controller])
                return
            }

            self.loadData { (result, error) -> Void in

                guard let result = result else {
                    completion(nil, error, nil)
                    return
                }

                guard result.availableLocales.count > 0 && result.items.count > 0 else {
                    let controller = UIAlertController.cancellableAlertConroller("No phone number found", message: error?.localizedDescription, handler: nil)
                    completion(nil, error, ["parsed":result, "viewController":controller])
                    return
                }

                let controller = UIAlertController(title: "Pick a number:", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
                    controller.dismiss(animated: true, completion: nil)
                }))

                for x in result.items where x.fullPhoneNumber != nil {
                    controller.addAction(UIAlertAction(title: "(\(x.locale.uppercased())) \(x.fullPhoneNumber!)", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                        self.dialPhonenumber(x)
                    }))
                }
                completion(nil, error, ["parsed":result, "viewController":controller])
            }
        }
    }

    open func unload(_ moment:Moment) {
    }

    func dialPhonenumber(_ number: SpeeddialMomentData.ContactData) {
        let country = number.countryCode ?? ""
        let area = number.areaCode ?? ""
        let exchange = number.exchangeNumber ?? ""
        let ext: String

        if let extens = number.lineNumber , extens.characters.count > 0 {
            ext = ",\(extens)"
        } else {
            ext = ""
        }

        let tel = "tel://\(country)\(area)\(exchange)\(ext)"
        print(tel)
        if let url = URL(string: tel) , UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        } else {
            let error = UIAlertController.cancellableAlertConroller("Unavailable", message: "Phone feature is not supported with your device", handler: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(error, animated: true, completion: nil)
        }
    }

    func loadData(_ completion:@escaping (_ result:SpeeddialMomentData?, _ error: NSError?) -> Void) {
        _ = SpeedDialMomentRequest.getContacts(moment: self.moment, allLocales: true) { (data, error) -> Void in
            if let data = data {
                completion(data, error)
            } else {
                completion(nil, error)
            }
        }.execute()
    }



    // MARK: - Moment Data
    open class SpeeddialMomentData : AbstractMomentData {

        open class ContactData : NSObject {
            open var locale: String!
            open var name: String?
            open var firstname: String?
            open var lastname: String?
            open var address: String?
            open var email: String?
            open var title: String?
            open var summary: String?
            open var type: String?
            open var countryCode: String?
            open var areaCode: String?
            open var exchangeNumber: String?
            open var lineNumber: String?
            open var fullPhoneNumber: String?

            open func getName() -> String? {
                return name ?? firstname ?? lastname ?? title
            }

            init?(dictionary: NSDictionary) {
                summary = dictionary.htmlDecodedString("description")
                title = dictionary.htmlDecodedString("title")
                name = dictionary.htmlDecodedString("name")
                firstname = dictionary.htmlDecodedString("firstname")
                lastname = dictionary.htmlDecodedString("lastname")
                email = dictionary.htmlDecodedString("email")
                address = dictionary.htmlDecodedString("address")
                type = dictionary.htmlDecodedString("type")
                countryCode = dictionary.htmlDecodedString("countryCode")
                areaCode = dictionary.htmlDecodedString("areaCode")
                exchangeNumber = dictionary.htmlDecodedString("exchangeNumber")
                lineNumber = dictionary.htmlDecodedString("lineNumber")
                fullPhoneNumber = dictionary.htmlDecodedString("fullPhoneNumber")
            }

        }

        open var items:[ContactData] = []

        override init?(dictionary: NSDictionary) {
            super.init(dictionary: dictionary)
            readFromDictionary(dictionary)
        }

        public required init?(response: HTTPURLResponse, representation: AnyObject) {
            super.init(response: response, representation: representation)
            readFromDictionary(representation as! NSDictionary)
        }

        fileprivate func readFromDictionary(_ dictionary: NSDictionary) {
            print(dictionary)
            self.items.removeAll()
            for (locale, value) in dictionary as! [String: NSDictionary] {
                let items = value.value(forKey: "phoneNumbers") as? [[String:AnyObject]]
                if let items = items {
                    for data in items {
                        if let item = ContactData(dictionary: data as NSDictionary) {
                            item.locale = locale
                            self.items.append(item)
                        }
                    }
                }
            }
            self.availableLocales.append(contentsOf: dictionary.allKeys as! [String])
        }
    }
}

enum SpeedDialMomentRequest : Requestable {

    // --- cases
    case getContacts(moment: Moment, allLocales: Bool, completion:(_ data: SpeeddialMoment.SpeeddialMomentData?, _ error: NSError?) -> Void)
    case getContact(moment: Moment, contactID: Int, completion:(_ data: SpeeddialMoment.SpeeddialMomentData?, _ error: NSError?) -> Void)

    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }

    var baseURI: String {
        switch self {
        case let .getContacts(moment, allLocales, _):
            return moment.launchURL + "/SpeedDialBits" + (allLocales ? "?alllocales=true" : "")
        case let .getContact(moment, contactID, _):
            return moment.launchURL + "/SpeedDialBits/\(contactID)"
        }
    }

    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getContacts(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: SpeeddialMoment.SpeeddialMomentData?, error) -> Void in
                completion(data, error)
            }
        case .getContact(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: SpeeddialMoment.SpeeddialMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}

