//
//  MomentHelper.swift
//  Flybits
//
//  Created by chu on 2015-09-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

class LiteMomentManager : MomentManager {
    public override init() {
        super.init()
//        com.flybits.moments.poll
//        com.flybits.moments.lists

        _ = registerModule("com.flybits.moments.location") { _,_,_ in
            return LiteMomentManager.moduleForStoryboardID("mm_location")
        }
        _ = registerModule("com.flybits.moments.event") { _,_,_ in
            return LiteMomentManager.moduleForStoryboardID("mm_event")
        }
        _ = registerModule("com.flybits.moments.youtube") { _,_,_ in
            return LiteMomentManager.moduleForStoryboardID("mm_youtube")
        }
        _ = registerModule("com.flybits.moments.user", "com.flybits.moments.users") { _,_,_ in
            return LiteMomentManager.moduleForStoryboardID("mm_userlist")
        }
        _ = registerModule("com.flybits.moments.gallery") { _,_,_ in
            return LiteMomentManager.moduleForStoryboardID("mm_image_gallery")
        }
        _ = registerModule("com.flybits.moments.website") { _,_,_ in
            return WebPageMomentViewController()
        }
        _ = registerModule("com.flybits.moments.text") { _,_,_ in
            return TextMomentViewController()
        }
        _ = registerModule("com.flybits.moments.twitter") { _,_,_ in
            return TwitterMomentViewController()
        }
        _ = registerModule("com.flybits.moments.speedial") { _, _, _ in
            return SpeeddialMoment()
        }
        _ = registerModule("com.flybits.moments.nativeapp") { _, _, _ in
            return NativeAppMoment()
        }
        unregisteredModuleHandler = { (manager: MomentManager, packageName: String, moment: Moment) -> MomentModule? in
            if moment.launchURL.lowercased().contains("/locationbit/") {
                return LiteMomentManager.moduleForStoryboardID("mm_location")
            } else if moment.renditionType == Moment.RenditionType.html {
                return HTMLMomentViewController()
            }
            return nil
        }
    }

    fileprivate static func moduleForStoryboardID(_ name:String) -> MomentModule? {
        let story = UIStoryboard(name: "Moments", bundle: nil)
        return story.instantiateViewController(withIdentifier: name) as? MomentModule
    }

    open static let sharedManager: MomentManager = LiteMomentManager()
}


public extension Moment {

    public func loadData(_ suffix:String?, completion:@escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {

        let req = URLRequest(url: NSURL(string: "\(launchURL)" + (suffix != nil ? "/\(suffix!)" : ""))! as URL)
        print("\(req.url?.absoluteString)")
        let task = URLSession.shared.dataTask(with: req, completionHandler: completion)
        task.resume()
        return task
    }
}


open class AbstractMomentData : NSObject, ResponseObjectSerializable {

    open var dateAdded: Date = Date(timeIntervalSince1970: 0)
    open var dateModified: Date = Date(timeIntervalSince1970: 0)
    open var summary: String?
    open var id: Int = -1
    open var locale: Locale = Locale(identifier: "en")
    open var availableLocales:[String] = []
    open var title: String?


    public init?(dictionary:NSDictionary) {
        super.init()
        self.readFromDictionary(dictionary)
    }

    public required init?(response: HTTPURLResponse, representation: AnyObject) {
        super.init()
        guard let rep = representation as? NSDictionary else {
            return nil
        }
        self.readFromDictionary(rep)
    }

    fileprivate func readFromDictionary(_ dictionary: NSDictionary) {
        dateAdded = dictionary.dateForKey("dateAdded")
        dateModified = dictionary.dateForKey("dateModified")
        summary = dictionary.htmlDecodedString("description")
        id = dictionary.numForKey("id")?.intValue ?? -1

        if let localeIdentifier = dictionary.htmlDecodedString("locale") , localeIdentifier != "en" {
            locale = Locale(identifier: localeIdentifier)
        }
        title = dictionary.htmlDecodedString("title")
    }

}

internal extension NSDictionary {
    func numForKey(_ key:String) -> NSNumber? {
        return self.value(forKey: key) as? NSNumber
    }

    func dateForKey(_ key:String) -> Date {
        return Date(timeIntervalSince1970: numForKey(key)?.doubleValue ?? 0)
    }

    func htmlDecodedString(_ keyPath: String) -> String? {
        return (self.value(forKeyPath: keyPath) as? String)?.Lite_HTMLDecodedString
    }
}

public var CurrentLocaleCode: String {
    return (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String ?? "EN"
}
