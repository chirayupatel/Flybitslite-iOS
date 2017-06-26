//
// CalendarEventUser.swift
// Copyright (c) :YEAR: Flybits (http://flybits.com)
//
// Permission to use this codebase and all related and dependent interfaces
// are granted as bound by the licensing agreement between Flybits and
// :COMPANY_NAME: effective :EFFECTIVE_DATE:.
//
// Flybits Framework version :VERSION:
// Built: :BUILD_DATE:
//

import Foundation
import FlybitsSDK

enum CalendarEventUserStatus: String {
    case accepted
    case declinded
    case undecided
}

enum CalendarEventAttendeeMomentRequest: Requestable {
    case getAttendee(moment: Moment, jwtToken: String, attendeeId: String, completion: (CalendarEventUser?, NSError?) -> Void)
    case getAttendees(moment: Moment, jwtToken: String, email: String?, pager: Pager?, sortBy: String?, order: SortOrder?, completion: ([CalendarEventUser]?, Pager?, NSError?) -> Void)
    case getAttendeesInvitedTo(moment: Moment, jwtToken: String, eventId: String, pager: Pager?, sortBy: String?, order: SortOrder?, completion: ([CalendarEventUser]?, Pager?, NSError?) -> Void)
    
    var requestType: FlybitsRequestType {
        return .custom
    }
    
    var baseURI: String {
        switch self {
        case .getAttendee(let moment, _, let attendeeId, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.calendarAttendeesEndpoint)/\(attendeeId)"
        case .getAttendees(let moment, _, let email, let pager, let sortBy, let order, _):
            var params = [String]()
            var joinedParams = ""
            if let email = email {
                params.append("email=\(email)")
            }
            if let pager = pager {
                params.append("limit=\(pager.limit)&offset\(pager.offset)")
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
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.calendarAttendeesEndpoint)\(joinedParams)"
        case .getAttendeesInvitedTo(let moment, _, let eventId, _, _, _, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.eventsEndpoint)/\(eventId)\(CalendarMoment.APIConstants.calendarAttendeesEndpoint)"
        }
    }
    
    var method: HTTPMethod {
        return .GET
    }
    
    var encoding: HTTPEncoding {
        return .json
    }
    
    var headers: [String: String] {
        switch self {
        case .getAttendee(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .getAttendees(_, let jwtToken, _, _, _, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .getAttendeesInvitedTo(_, let jwtToken, _, _, _, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        }
    }
    
    var path: String {
        return ""
    }
    
    func execute() -> FlybitsRequest {
        switch self {
        case .getAttendee(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEventUser?, error) -> Void in
                completion(eventData, error)
            }
        case .getAttendees(_, _, _, _, _, _, let completion), .getAttendeesInvitedTo(_, _, _, _, _, _, let completion):
            return FlybitsRequest(urlRequest).responseListPaged { (request, response, eventData: [CalendarEventUser]?, pager, error) -> Void in
                completion(eventData, pager, error)
            }
        }
    }
}

class CalendarEventUser: NSObject, ResponseObjectSerializable, DictionaryConvertible {
    
    struct Constant {
        static let tenantId = "tenantId"
        static let deviceId = "deviceId"
        static let isFlybitsUser = "isFlybitsUser"
        static let userId = "userId"
        static let firstName = "firstName"
        static let lastName = "lastName"
        static let email = "email"
        static let phoneNumber = "phoneNumber"
        static let status = "status"
        static let iconUrl = "iconUrl"
    }
    
    var tenantId: String?
    var deviceId: String?
    var isFlybitsUser: Bool?
    var userId: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var phoneNumber: String?
    var status: CalendarEventUserStatus? = .undecided
    var iconUrl: URL?
    
    override required init() {
        super.init()
    }
    
    convenience required init?(response: HTTPURLResponse, representation: AnyObject) {
        self.init()
        
        guard let representation = representation as? [String: Any] else {
            return nil
        }
        
        tenantId = representation[Constant.tenantId] as? String
        deviceId = representation[Constant.deviceId] as? String
        isFlybitsUser = representation[Constant.isFlybitsUser] as? Bool
        userId = representation[Constant.userId] as? String
        firstName = representation[Constant.firstName] as? String
        lastName = representation[Constant.lastName] as? String
        email = representation[Constant.email] as? String
        phoneNumber = representation[Constant.phoneNumber] as? String
        status = representation[Constant.status] as? CalendarEventUserStatus ?? .undecided
        if let icon = representation[Constant.iconUrl] as? String {
            iconUrl = URL(string: icon)
        }
    }
    
    func toDictionary() throws -> [String: AnyObject] {
        var dict = [String: Any]()
        if let tenantId = tenantId {
            dict[Constant.tenantId] = tenantId
        }
        if let deviceId = deviceId {
            dict[Constant.deviceId] = deviceId
        }
        if let isFlybitsUser = isFlybitsUser {
            dict[Constant.isFlybitsUser] = isFlybitsUser
        }
        if let userId = userId {
            dict[Constant.userId] = userId
        }
        if let firstName = firstName {
            dict[Constant.firstName] = firstName
        }
        if let lastName = lastName {
            dict[Constant.lastName] = lastName
        }
        if let email = email {
            dict[Constant.email] = email
        }
        if let phoneNumber = phoneNumber {
            dict[Constant.phoneNumber] = phoneNumber
        }
        if let status = status {
            dict[Constant.status] = status.rawValue
        }
        if let iconUrl = iconUrl {
            dict[Constant.iconUrl] = iconUrl.absoluteString
        }
        return dict as [String: AnyObject]
    }
}
