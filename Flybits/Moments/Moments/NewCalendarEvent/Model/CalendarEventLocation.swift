//
//  CalendarEventLocation.swift
//  Flybits
//
//  Created by Alex on 5/18/17.
//  Copyright © 2017 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

enum CalendarEventLocationMomentRequest: Requestable {
    case getLocation(moment: Moment, jwtToken: String, locationId: String, completion: (CalendarEventLocation?, NSError?) -> Void)
    case getLocations(moment: Moment, jwtToken: String, name: String?, locale: Locale?, pager: Pager?, orderBy: String?, sortOrder: SortOrder?, completion: ([CalendarEventLocation]?, Pager?, NSError?) -> Void)
    case addLocation(moment: Moment, jwtToken: String, location: CalendarEventLocation, completion: (CalendarEventLocation?, NSError?) -> Void)
    case updateLocation(moment: Moment, jwtToken: String, location: CalendarEventLocation, completion: (CalendarEventLocation?, NSError?) -> Void)
    case deleteLocation(moment: Moment, jwtToken: String, locationId: String, completion: (NSError?) -> Void)
    
    var requestType: FlybitsRequestType {
        return .custom
    }
    
    var baseURI: String {
        switch self {
        case .getLocation(let moment, _, let locationId, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.locationsEndpoint)/\(locationId)"
        case .getLocations(let moment, _, let name, let locale, let pager, let sortBy, let order, _):
            var params = [String]()
            var joinedParams = ""
            if let name = name {
                params.append("name=\(name)")
            }
            if let locale = locale {
                params.append("locale=\(locale.languageCode!)")
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
                joinedParams = "/?\(params.joined(separator: "&"))"
            }
            
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.locationsEndpoint)\(joinedParams)"
        case .addLocation(let moment, _, _, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.locationsEndpoint)"
        case .updateLocation(let moment, _, let location, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.locationsEndpoint)/\(location.identifier!)"
        case .deleteLocation(let moment, _, let locationId, _):
            return "\(moment.launchURL)\(CalendarMoment.APIConstants.locationsEndpoint)/\(locationId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getLocation(_, _, _, _):
            return .GET
        case .getLocations(_, _, _, _, _, _, _, _):
            return .GET
        case .addLocation(_, _, _, _):
            return .POST
        case .updateLocation(_, _, _, _):
            return .PUT
        case .deleteLocation(_, _, _, _):
            return .DELETE
        }
    }
    
    var encoding: HTTPEncoding {
        return .json
    }
    
    var headers: [String: String] {
        switch self {
        case .getLocation(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .getLocations(_, let jwtToken, _, _, _, _, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .addLocation(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .updateLocation(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        case .deleteLocation(_, let jwtToken, _, _):
            return ["Accept": "application/json", "Content-Type": "application/json", "X-Authorization": jwtToken]
        }
    }
    
    var path: String {
        return ""
    }
    
    func execute() -> FlybitsRequest {
        switch self {
        case .getLocation(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEventLocation?, error) -> Void in
                completion(eventData, error)
            }
        case .getLocations(_, _, _, _, _, _, _, let completion):
            return FlybitsRequest(urlRequest).responseListPaged { (request, response, eventData: [CalendarEventLocation]?, pager, error) -> Void in
                completion(eventData, pager, error)
            }
        case .addLocation(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEventLocation?, error) -> Void in
                completion(eventData, error)
            }
        case .updateLocation(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEventLocation?, error) -> Void in
                completion(eventData, error)
            }
        case .deleteLocation(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: CalendarEventLocation?, error) -> Void in
                completion(error)
            }
        }
    }
}

class CalendarEventLocation: NSObject, ResponseObjectSerializable, DictionaryConvertible {
    
    struct Constant {
        static let identifier = "id"
        static let latitude = "lat"
        static let longitude = "lng"
        static let address = "address"
        static let name = "name"
        static let description = "description"
        static let phoneNumber = "phoneNumber"
        static let city = "city"
        static let province = "province"
        static let country = "country"
        
        static let localizations = "localizations"
    }
    
    var identifier: String?
    var lat: Double?
    var lng: Double?
    var address: LocalizedObject<String>?
    var name: LocalizedObject<String>?
    var locationDescription: LocalizedObject<String>?
    var phoneNumber: LocalizedObject<String>?
    var city: LocalizedObject<String>?
    var province: LocalizedObject<String>?
    var country: LocalizedObject<String>?
    
    required init?(response: HTTPURLResponse, representation: AnyObject) {
        super.init()
        
        guard let representation = representation as? [String: Any] else {
            return nil
        }
        
        identifier = representation[Constant.identifier] as? String
        if let latitude = representation[Constant.latitude] as? Int {
            self.lat = Double(latitude)
        } else if let latitude = representation[Constant.latitude] as? Float {
            self.lat = Double(latitude)
        } else if let latitude = representation[Constant.latitude] as? Double {
            self.lat = latitude
        }
        if let longitude = representation[Constant.longitude] as? Int {
            self.lng = Double(longitude)
        } else if let longitude = representation[Constant.longitude] as? Float {
            self.lng = Double(longitude)
        } else if let longitude = representation[Constant.longitude] as? Double {
            self.lng = longitude
        }
        
        if let localizationDict = representation[Constant.localizations] as? NSDictionary {
            address = LocalizedObject<String>(key: Constant.address, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            name = LocalizedObject<String>(key: Constant.name, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            locationDescription = LocalizedObject<String>(key: Constant.description, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            phoneNumber = LocalizedObject<String>(key: Constant.phoneNumber, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            city = LocalizedObject<String>(key: Constant.city, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            province = LocalizedObject<String>(key: Constant.province, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
            country = LocalizedObject<String>(key: Constant.country, localization: localizationDict, defaultLocale: Locale.current, decodeHTML: false)
        }
    }
    
    func toDictionary() throws -> [String: AnyObject] {
        var dict = [String: Any]()
        if let identifier = identifier {
            dict[Constant.identifier] = identifier
        }
        if let latitude = self.lat {
            dict[Constant.latitude] = latitude
        }
        if let longitude = self.lng {
            dict[Constant.longitude] = longitude
        }
        
        let nonNilVars: [LocalizedObject<String>] = [address, name, locationDescription, phoneNumber, city, province, country].flatMap { $0 }
        let localizations: [Locale] = nonNilVars.flatMap { $0.localizations }
        let unique: [Locale] = Array(Set(localizations))
        
        var localizationsDict = [String: Any]()
        for locale in unique {
            var localeDict = [String: String]()
            do {
                if let address = try address?.value(for: locale) {
                    localeDict[Constant.address] = address
                }
                if let name = try name?.value(for: locale) {
                    localeDict[Constant.name] = name
                }
                if let locationDescription = try locationDescription?.value(for: locale) {
                    localeDict[Constant.description] = locationDescription
                }
                if let phoneNumber = try phoneNumber?.value(for: locale) {
                    localeDict[Constant.phoneNumber] = phoneNumber
                }
                if let city = try city?.value(for: locale) {
                    localeDict[Constant.city] = city
                }
                if let province = try province?.value(for: locale) {
                    localeDict[Constant.province] = province
                }
                if let country = try country?.value(for: locale) {
                    localeDict[Constant.country] = country
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
        
        return dict as [String: AnyObject]
    }
}
