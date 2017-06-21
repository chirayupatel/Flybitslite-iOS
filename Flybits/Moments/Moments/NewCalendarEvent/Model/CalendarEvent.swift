//
//  CalendarEvent.swift
//  Flybits
//
//  Created by Alex on 5/18/17.
//  Copyright © 2017 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

enum CalendarEventError: Error {
    case localizedValueError
    case ownerDeserializationError
    case inviteesDeserializationError
    case lastModifiedByDeserializationError
    case locationDeserializationError
}

enum CalendarEventType: String {
    case publicEvent
    case privateEvent
    
    var rawValue: String {
        switch self {
        case .publicEvent: return "public"
        case .privateEvent: return "private"
        }
    }
}

class CalendarEventQuery: NSObject {
    var pager: Pager?
    var sortBy: String?
    var order: SortOrder?
    var type: CalendarEventType?
    var startTime: Double?
    var endTime: Double?
    
    init(pager: Pager?, sortBy: String?, order: SortOrder?, type: CalendarEventType?, startTime: Double?, endTime: Double?) {
        self.pager = pager
        self.sortBy = sortBy
        self.order = order
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
    }
    
    func toParams() -> String {
        var params = [String]()
        var joinedParams = ""
        if let type = type {
            params.append("type=\(type.rawValue)")
        }
        if let pager = pager {
            params.append("limit=\(pager.limit)&offset=\(pager.offset)")
        }
        if let sortBy = sortBy {
            params.append("sortBy=\(sortBy)")
        }
        if let order = order {
            params.append("order=\(order == .ascending ? "asc" : "desc")")
        }
        
        if params.count > 0 {
            joinedParams = "?\(params.joined(separator: "&"))"
        }
        return joinedParams
    }
}

enum CalendarEventMomentRequest: Requestable {
    
    case getEvent(moment: Moment, jwtToken: String, eventId: String, completion: (CalendarEvent?, NSError?) -> Void)
    case getEvents(moment: Moment, jwtToken: String, query: CalendarEventQuery?, completion: ([CalendarEvent]?, Pager?, NSError?) -> Void)
    case addEvent(moment: Moment, jwtToken: String, event: CalendarEvent, completion: (CalendarEvent?, NSError?) -> Void)
    case updateEvent(moment: Moment, jwtToken: String, event: CalendarEvent, completion: (CalendarEvent?, NSError?) -> Void)
    case deleteEvent(moment: Moment, jwtToken: String, eventId: String, completion: (NSError?) -> Void)
    
    var requestType: FlybitsRequestType {
        return .custom
    }
    
    var baseURI: String {
        switch self {
        case .getEvent(let moment, _, let eventId, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.eventsEndpoint)/\(eventId)"
        case .getEvents(let moment, _, let query, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.eventsEndpoint)\(((query != nil) ? query!.toParams() : ""))"
        case .addEvent(let moment, _, _, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.eventsEndpoint)"
        case .updateEvent(let moment, _, let event, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.eventsEndpoint)/\(event.identifier!)"
        case .deleteEvent(let moment, _, let eventId, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.eventsEndpoint)/\(eventId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getEvent(_, _, _, _):
            return .GET
        case .getEvents(_, _, _, _):
            return .GET
        case .addEvent(_, _, _, _):
            return .POST
        case .updateEvent(_, _, _, _):
            return .PUT
        case .deleteEvent(_, _, _, _):
            return .DELETE
        }
    }
    
    var encoding: HTTPEncoding {
        return .json
    }
    
    var headers: [String: String] {
        switch self {
        case .getEvent(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .getEvents(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .addEvent(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .updateEvent(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .deleteEvent(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        }
    }
    
    var parameters: [String: AnyObject]? {
        switch self {
        case .addEvent(_, _, let event, _):
            var dict: [String: AnyObject]
            do {
                dict = try event.toDictionary()
            } catch {
                print(error.localizedDescription)
                dict = [:]
            }
            return dict
        case .updateEvent(_, _, let event, _):
            var dict: [String: AnyObject]
            do {
                dict = try event.toDictionary()
            } catch {
                print(error.localizedDescription)
                dict = [:]
            }
            return dict
        default:
            return nil
        }
    }
    
    var path: String {
        return ""
    }
    
    func execute() -> FlybitsRequest {
        switch self {
        case .getEvent(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEvent?, error) -> Void in
                completion(eventData, error)
            }
        case .getEvents(_, _, _, let completion):
            return FlybitsRequest(urlRequest).responseListPaged { (request, response, eventData: [CalendarEvent]?, pager, error) -> Void in
                completion(eventData, pager, error)
            }
        case .addEvent(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEvent?, error) -> Void in
                completion(eventData, error)
            }
        case .updateEvent(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEvent?, error) -> Void in
                completion(eventData, error)
            }
        case .deleteEvent(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEvent?, error) -> Void in
                completion(error)
            }
        }
    }
}

class CalendarEvent: NSObject, ResponseObjectSerializable, DictionaryConvertible {
    
    struct Constant {
        static let identifier = "id"
        static let tenantId = "tenantId"
        static let startTime = "startTime"
        static let endTime = "endTime"
        static let title = "title"
        static let subtitle = "subtitle"
        static let description = "description"
        static let isAllDay = "isAllDay"
        static let owner = "owner"
        static let invitees = "invitees"
        static let createdAt = "createdAt"
        static let modifiedAt = "modifiedAt"
        static let deletedAt = "deletedAt"
        static let lastModifiedBy = "lastModifiedBy"
        static let location = "location"
        static let colour = "colour"
        static let eventType = "type"
        
        static let localizations = "localizations"
    }
    
    var identifier: String?
    var tenantId: String?
    var startTime: Double?
    var endTime: Double?
    var title: LocalizedObject<String>?
    var subtitle: LocalizedObject<String>?
    var eventDescription: LocalizedObject<String>?
    var isAllDay: Bool?
    var owner: CalendarEventUser?
    var invitees: [CalendarEventUser]?
    var createdAt: Double?
    var modifiedAt: Double?
    var deletedAt: Double?
    var lastModifiedBy: CalendarEventUser?
    var location: CalendarEventLocation?
    var colour: String?
    var eventType: CalendarEventType? = .publicEvent
    
    required init?(response: HTTPURLResponse, representation: AnyObject) {
        super.init()
        
        guard let representation = representation as? [String: Any] else {
            return nil
        }
        
        self.identifier = representation[Constant.identifier] as? String
        self.tenantId = representation[Constant.tenantId] as? String
        if let startTime = representation[Constant.startTime] as? Int {
            self.startTime = Double(startTime)
        } else if let startTime = representation[Constant.startTime] as? Float {
            self.startTime = Double(startTime)
        } else if let startTime = representation[Constant.startTime] as? Double {
            self.startTime = startTime
        }
        if let endTime = representation[Constant.endTime] as? Int {
            self.endTime = Double(endTime)
        } else if let endTime = representation[Constant.endTime] as? Float {
            self.endTime = Double(endTime)
        } else if let endTime = representation[Constant.endTime] as? Double {
            self.endTime = endTime
        }
        self.isAllDay = representation[Constant.isAllDay] as? Bool
        if let attendee = representation[Constant.owner] as? [String: Any] {
            self.owner = CalendarEventUser(response: response, representation: attendee as AnyObject)
        }
        if let attendees = representation[Constant.invitees] as? [[String: Any]] {
            self.invitees = attendees.map { CalendarEventUser(response: response, representation: $0 as AnyObject)! }
        }
        if let createdAt = representation[Constant.createdAt] as? Int {
            self.createdAt = Double(createdAt)
        } else if let createdAt = representation[Constant.createdAt] as? Float {
            self.createdAt = Double(createdAt)
        } else if let createdAt = representation[Constant.createdAt] as? Double {
            self.createdAt = createdAt
        }
        if let modifiedAt = representation[Constant.modifiedAt] as? Int {
            self.modifiedAt = Double(modifiedAt)
        } else if let modifiedAt = representation[Constant.modifiedAt] as? Float {
            self.modifiedAt = Double(modifiedAt)
        } else if let modifiedAt = representation[Constant.modifiedAt] as? Double {
            self.modifiedAt = modifiedAt
        }
        if let deletedAt = representation[Constant.deletedAt] as? Int {
            self.deletedAt = Double(deletedAt)
        } else if let deletedAt = representation[Constant.deletedAt] as? Float {
            self.deletedAt = Double(deletedAt)
        } else if let deletedAt = representation[Constant.deletedAt] as? Double {
            self.deletedAt = deletedAt
        }
        if let last = representation[Constant.lastModifiedBy] as? [String: Any] {
            self.lastModifiedBy = CalendarEventUser(response: response, representation: last as AnyObject)
        }
        if let location = representation[Constant.location] as? [String: Any] {
            self.location = CalendarEventLocation(response: response, representation: location as AnyObject)!
        }
        self.colour = representation[Constant.colour] as? String
        if let eventType = representation[Constant.eventType] as? CalendarEventType {
            self.eventType = eventType
        }
        
        if let localizationDict = representation[Constant.localizations] as? NSDictionary {
            self.title = LocalizedObject<String>(key: Constant.title, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            self.subtitle = LocalizedObject<String>(key: Constant.subtitle, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            self.eventDescription = LocalizedObject<String>(key: Constant.description, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
        }
    }
    
    func toDictionary() throws -> [String: AnyObject] {
        var dict = [String: Any]()
        if let identifier = identifier {
            dict[Constant.identifier] = identifier
        }
        if let tenantId = tenantId {
            dict[Constant.tenantId] = tenantId
        }
        if let startTime = startTime {
            dict[Constant.startTime] = Int(floor(startTime))
        }
        if let endTime = endTime {
            dict[Constant.endTime] = Int(floor(endTime))
        }
        
        let nonNilVars: [LocalizedObject<String>] = [title, subtitle, eventDescription].flatMap { $0 }
        let localizations: [Locale] = nonNilVars.flatMap { $0.localizations }
        let unique: [Locale] = Array(Set(localizations))
        
        var localizationsDict = [String: Any]()
        for locale in unique {
            var localeDict = [String: String]()
            do {
                if let title = try title?.value(for: locale) {
                    localeDict[Constant.title] = title
                }
                if let subtitle = try subtitle?.value(for: locale) {
                    localeDict[Constant.subtitle] = subtitle
                }
                if let eventDescription = try eventDescription?.value(for: locale) {
                    localeDict[Constant.description] = eventDescription
                }
            } catch {
                print(error.localizedDescription)
                throw CalendarEventError.localizedValueError
            }
            
            if localeDict.count > 0 {
                localizationsDict[locale.languageCode!] = localeDict
            }
        }
        
        dict[Constant.localizations] = localizationsDict
        
        if let isAllDay = isAllDay {
            dict[Constant.isAllDay] = isAllDay
        }
        if let owner = owner {
            do {
                dict[Constant.owner] = try owner.toDictionary()
            } catch {
                throw CalendarEventError.ownerDeserializationError
            }
        }
        if let invitees = invitees {
            var userArray = [[String: Any]]()
            for invitee in invitees {
                var i: [String: Any]
                do {
                    i = try invitee.toDictionary()
                } catch {
                    throw CalendarEventError.inviteesDeserializationError
                }
                userArray.append(i)
            }
            dict[Constant.invitees] = userArray
        }
        if let createdAt = createdAt {
            dict[Constant.createdAt] = createdAt
        }
        if let modifiedAt = modifiedAt {
            dict[Constant.modifiedAt] = modifiedAt
        }
        if let deletedAt = deletedAt {
            dict[Constant.deletedAt] = deletedAt
        }
        if let lastModifiedBy = lastModifiedBy {
            do {
                dict[Constant.lastModifiedBy] = try lastModifiedBy.toDictionary()
            } catch {
                throw CalendarEventError.lastModifiedByDeserializationError
            }
        }
        if let location = location {
            do {
                dict[Constant.location] = try location.toDictionary()
            } catch {
                throw CalendarEventError.locationDeserializationError
            }
        }
        if let colour = colour {
            dict[Constant.colour] = colour
        }
        if let eventType = eventType {
            dict[Constant.eventType] = eventType.rawValue
        }
        
        return dict as [String: AnyObject]
    }
}
