//
//  EventMomentModels.swift
//  Flybits
//
//  Created by chu on 2015-10-21.
//  Copyright © 2015 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

open class EventBaseModel: ResponseObjectSerializable {
    open var id: Int
    open var dateAdded: Int
    open var dateModified: Int
    open var title: String
    open var summary: String
    open var facebookShareMessage: String
    open var twitterShareMessage: String
    open var linkedInShareMessage: String
    open var instagramShareMessage: String
    open var phoneNumber: String?

    public required init?(response: HTTPURLResponse, representation: AnyObject) {
        id = representation.value(forKey: "id") as? Int ?? -1
        dateAdded = representation.value(forKey: "dateAdded") as? Int ?? -1
        dateModified = representation.value(forKey: "dateModified") as? Int ?? -1
        title = (representation.value(forKey: "title") as? String ?? "").htmlDecodedString
        summary = (representation.value(forKey: "description") as? String ?? "").htmlDecodedString
        facebookShareMessage = (representation.value(forKey: "facebookShareMessage") as? String ?? "").htmlDecodedString
        twitterShareMessage = (representation.value(forKey: "twitterShareMessage") as? String ?? "").htmlDecodedString
        linkedInShareMessage = (representation.value(forKey: "linkedInShareMessage") as? String ?? "").htmlDecodedString
        instagramShareMessage = (representation.value(forKey: "instagramShareMessage") as? String ?? "").htmlDecodedString
        phoneNumber = (representation.value(forKey: "phoneNumber") as? String)?.htmlDecodedString
    }
}

open class EventAttachment: ResponseObjectSerializable {
    open var eventID: Int
    open var fileName: String
    open var fileExtension: String
    open var fileURL: String

    public required init?(response: HTTPURLResponse, representation: AnyObject) {
        eventID = representation.value(forKey: "eventId") as? Int ?? -1
        fileName = (representation.value(forKey: "fileName") as? String ?? "").htmlDecodedString
        fileExtension = (representation.value(forKey: "fileExtension") as? String ?? "").htmlDecodedString
        fileURL = (representation.value(forKey: "fileUrl") as? String ?? "").htmlDecodedString
    }
}

open class EventAttachmentVideo: EventAttachment {
    open var type: String
    open var youtubeURL: String

    public required init?(response: HTTPURLResponse, representation: AnyObject) {
        type = (representation.value(forKey: "type") as? String ?? "").htmlDecodedString
        youtubeURL = (representation.value(forKey: "youtubeUrl") as? String ?? "").htmlDecodedString

        super.init(response: response, representation: representation)
    }
}

open class Event: EventBaseModel {
    open var startDate: Int
    open var endDate: Int
    open var eventName: String
    open var galleryTitle: String
    open var galleryDescription: String
    open var location: String
    open var imageURL: String
    open var images: [EventAttachment]?
    open var videos: [EventAttachmentVideo]?
    open var localizations: [LocalizedEvent]?

    public required init?(response: HTTPURLResponse, representation: AnyObject) {
        startDate    = representation.value(forKey: "startDate") as? Int ?? -1
        endDate      = representation.value(forKey: "endDate") as? Int ?? -1
        eventName    = (representation.value(forKey: "eventName") as? String ?? "").htmlDecodedString
        galleryTitle = (representation.value(forKey: "galleryTitle") as? String ?? "").htmlDecodedString
        galleryDescription = (representation.value(forKey: "galleryDescription") as? String ?? "").htmlDecodedString
        location     = (representation.value(forKey: "location") as? String ?? "").htmlDecodedString
        imageURL     = (representation.value(forKey: "imageUrl") as? String ?? "").htmlDecodedString

        super.init(response: response, representation: representation)
        
        images = Utils.parseListFromRawList(response, rawList: representation.value(forKey: "images") as? [AnyObject])
        videos = Utils.parseListFromRawList(response, rawList: representation.value(forKey: "videos") as? [AnyObject])

        if let locales = representation.value(forKey: "locales") as? [String: AnyObject] {
            var localiedObjs = [LocalizedEvent]()
            for (langCode, obj) in locales {
                if let localeObj = LocalizedEvent(response: response, representation: obj) {
                    localeObj.locale = langCode as NSString!
                    localiedObjs.append(localeObj)
                }
            }

            localizations = localiedObjs.count > 0 ? localiedObjs : nil
        }
    }

    /// when langCode is nil, any random localization is returned, otherwise one you asked for {if it exists} is returned
    func localization(_ langCode: String?) -> LocalizedEvent? {
        guard let langCode = langCode?.lowercased() else {
            return localizations?.first
        }

        if let items = localizations {
            for item in items where item.locale.lowercased == langCode {
                return item
            }
        }
        return nil
    }
}

open class LocalizedEvent : NSObject, ResponseObjectSerializable {

    open var locale: NSString!
    open var eventDescription = ""
    open var eventId = 0
    open var eventName = ""
    open var facebookShareMessage = ""
    open var galleryDescription = ""
    open var galleryTitle = ""
    open var instagramShareMessage = ""
    open var linkedInShareMessage = ""
    open var location = ""
    open var title = ""
    open var twitterShareMessage = ""
    open var phoneNumber: String?

    public required init?(response: HTTPURLResponse, representation: AnyObject) {
        super.init()

        guard let localizedItem = representation as? [String: AnyObject] else {
            return nil
        }

//        print(localizedItem)
//        print(representation)

        eventDescription      = (localizedItem["description"] as? String ?? "").htmlDecodedString
        eventId               = localizedItem["eventId"] as? Int ?? 0
        eventName             = (localizedItem["eventName"] as? String ?? "").htmlDecodedString
        facebookShareMessage  = (localizedItem["facebookShareMessage"] as? String ?? "").htmlDecodedString
        galleryDescription    = (localizedItem["galleryDescription"] as? String ?? "").htmlDecodedString
        galleryTitle          = (localizedItem["galleryTitle"] as? String ?? "").htmlDecodedString
        instagramShareMessage = (localizedItem["instagramShareMessage"] as? String ?? "").htmlDecodedString
        linkedInShareMessage  = (localizedItem["linkedInShareMessage"] as? String ?? "").htmlDecodedString
        location              = (localizedItem["location"] as? String ?? "").htmlDecodedString
        title                 = (localizedItem["title"] as? String ?? "").htmlDecodedString
        twitterShareMessage   = (localizedItem["twitterShareMessage"] as? String ?? "").htmlDecodedString
        phoneNumber           = (localizedItem["phoneNumber"] as? String)?.htmlDecodedString
    }
}


open class EventMomentData: AbstractMomentData {
    open var events: [Event]?

    public required init?(response: HTTPURLResponse, representation: AnyObject) {
        super.init(dictionary: representation as! NSDictionary)

        events = Utils.parseListFromRawList(response, rawList: representation.value(forKey: "events") as? [AnyObject])
    }
}
