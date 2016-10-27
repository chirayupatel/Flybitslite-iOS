//
//  ContextPlugin.swift
//  Flybits
//
//  Created by Archu on 2016-04-04.
//  Copyright © 2016 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

protocol ContextPluginValueType {}
extension Int32 : ContextPluginValueType {}
extension String : ContextPluginValueType { }
extension Bool : ContextPluginValueType { }

extension String {
    var boolVal: Bool {
        return (self as NSString).boolValue
    }
}

extension Bool {
    var stringVal: String {
        return self ? "True" : "False"
    }
}

class ContextPlugin {
    typealias CurrentstatusCallback = ((_ cp: ContextPlugin) -> (Bool?, ContextPluginPermissionType?))
    typealias RequesterCallback = ((_ cp: ContextPlugin) -> Void)
    typealias PermissionSuccessCallback = ((_ cp: ContextPlugin) -> Void)
    typealias AvailabilityCallback = ((_ cp: ContextPlugin) -> Bool)
    
    var enabled = true
    var editable = true
    var provider: ContextProvider!
    var contextDataProvider: ContextDataProvider!
    var title: String
    var permissionUserText: String? // displayed to user when asking for permission
    var permissionRequester: RequesterCallback? // ask permission to use this context plugin
    var availabilityChecker: AvailabilityCallback? // check if this context plugin is supported/available on this device..
    var currentStatus: CurrentstatusCallback? // what's the current permission/status of this context plugin
    var permissionSuccess: PermissionSuccessCallback? // call back to be called when user grants success permission
    var customisableProperties: [ContextPlugin.Property] = []
    
    init(provider: ContextProvider, name: String, setup:(_ p:ContextPlugin) -> Void) {
        self.provider = provider
        self.title = name
        setup(self)
    }
    
    init(name: String, setup:(_ p: ContextPlugin) -> Void) {
        self.title = name
        setup(self)
    }
    
    func freeze(_ editable:Bool=false) -> ContextPlugin {
        let tempSelf = self
        tempSelf.editable = editable
        return self
    }
    
    func addProperty(_ p: ContextPlugin.Property) -> ContextPlugin {
        p.plugin = self
        customisableProperties.append(p)
        return self
    }
    
    func property(_ key: String) -> ContextPlugin.Property? {
        for prop in customisableProperties where prop.key == key {
            return prop
        }
        return nil
    }
    
    func pollFreq(_ defaultValue: Int32?) -> Int32? {
        return property("pollFrequency")?.value as? Int32 ?? defaultValue
    }
    
    func uploadFreq(_ defaultValue: Int32?) -> Int32? {
        return property("uploadFreq")?.value as? Int32 ?? defaultValue
    }
}

extension ContextProvider {
    
    var stringVal: String {
        switch self {
        case .activity:         return "Activity"
        case .audio:            return "Audio"
        case .availability:     return "Availability"
        case .battery:          return "Battery"
        case .carrier:          return "Carrier"
        case .coreLocation:     return "CoreLocation"
        case .eddystone:        return "Eddystone"
        case .iBeacon:          return "iBeacon"
        case .language:         return "Language"
        case .network:          return "Network"
        case .oAuth:            return "OAuth"
        case .pedometerSteps:   return "PedometerSteps"
        }
    }
    
    init?(string: String) {
        switch string {
        case "Activity":       self.init(rawValue: ContextProvider.activity.rawValue);          break
        case "Availability":   self.init(rawValue: ContextProvider.availability.rawValue); 		break
        case "Battery": 	   self.init(rawValue: ContextProvider.battery.rawValue); 			break
        case "Carrier": 	   self.init(rawValue: ContextProvider.carrier.rawValue); 			break
        case "CoreLocation":   self.init(rawValue: ContextProvider.coreLocation.rawValue); 		break
        case "Eddystone": 	   self.init(rawValue: ContextProvider.eddystone.rawValue); 		break
        case "iBeacon": 	   self.init(rawValue: ContextProvider.iBeacon.rawValue); 			break
        case "Language": 	   self.init(rawValue: ContextProvider.language.rawValue); 			break
        case "Network": 	   self.init(rawValue: ContextProvider.network.rawValue); 			break
        case "OAuth":          self.init(rawValue: ContextProvider.oAuth.rawValue); 			break
        case "PedometerSteps": self.init(rawValue: ContextProvider.pedometerSteps.rawValue);    break
        case "Audio":          self.init(rawValue: ContextProvider.audio.rawValue);    break
        default:               return nil
        }
    }

}

protocol ContextPluginPermissionType {
    var stringVal: String { get }
}

struct PrivacyEnabledPluginPermissionType : ContextPluginPermissionType{
    var stringVal: String
}

// MARK: ContextPluginCustomizableProperty
extension ContextPlugin {
    
    class Property {
        weak var plugin: ContextPlugin!
        var editable = true
        var name: String
        var key: String
        var value: ContextPluginValueType {
            didSet {
                valueUpdated?()
            }
        }
        var toString: ((_ property: Property) -> String?)?
        var toValue: ((_ property: Property, _ value: String?) -> Property)?
        var valueUpdated:(()->Void)?
        var displayString:(() -> String?)?
        
        init(key: String, name: String, value: ContextPluginValueType) {
            
            self.key = key
            self.name = name
            self.value = value
        }
        
        init(key: String,
             name: String,
             value: ContextPluginValueType,
             toString:@escaping (_ property: Property) -> String?,
             toValue:@escaping (_ property: Property, _ value: String?) -> Property) {
            
            self.key = key
            self.name = name
            self.value = value
            self.toString = toString
            self.toValue = toValue
        }
        
        func freeze(_ editable:Bool=false) -> Property {
            self.editable = editable
            return self
        }
        
        // MARK: Predefined variables -- these are mostly useful for all the plugins
        static var enabled: Property {
            let p = Property(
                key: "enabled",
                name: "Status",
                value: true)
            p.toString = {
                return ($0.value as? Bool)?.stringVal ?? false.stringVal
            }
            p.toValue = { (prop, value) in
                let temp = prop
                temp.value = value?.boolVal ?? false
                return temp
            }
            p.valueUpdated = { [weak p] in
                if let p = p {
                    p.plugin.enabled = p.value as? Bool ?? false
                }
            }
            p.displayString = { [weak p] in
                if let p = p?.plugin.enabled {
                    return p ? "Active" : "Inactive"
                }
                
                return "-"
            }
            return p
        }
        
        static func pollFrequency(_ freq: Int32 = (5 * 60)) -> Property {
            let p = Property(
                key: "pollFrequency",
                name: "Poll Frequency",
                value: freq)
            p.toString = {
                return "\($0.value)"
            }
            p.toValue = { (prop, value) in
                let temp = prop
                guard let value = value, let intValue = Int32(value) else {
                    temp.value = Int32(0)
                    return temp
                }
                temp.value = intValue
                return temp
            }
            p.displayString = { [weak p] in
                if let p = p?.value as? Int32 {
                    return "\(p / 60) mins, \(p % 60) sec"
                }
                return "-"
            }
            return p
        }
        
        static func uploadFrequency(_ freq: Int32 = (5 * 60)) -> Property {
            let p = Property (
                key: "uploadfreq",
                name: "Upload Frequency",
                value: freq)
            p.toString = {
                return "\($0.value)"
            }
            p.toValue = { (prop, value) in
                let temp = prop
                guard let value = value, let intValue = Int32(value) else {
                    temp.value = Int32(0)
                    return temp
                }
                temp.value = intValue
                return temp
            }
            p.displayString = { [weak p] in
                if let p = p?.value as? Int32 {
                    return "\(p / 60) mins, \(p % 60) sec"
                }
                return "-"
            }
            return p
        }
        
        static var categoryType: Property {
            let p = Property (
                key: "category",
                name: "CategoryType",
                value: " ")
            p.toString = {
                return "\($0.value)"
            }
            p.toValue = { (prop, value) in
                let temp = prop
                temp.value = value ?? ""
                return temp
            }
            return p
        }
        
        static func permissionDisplayValue(_ p: ContextPluginPermissionType) -> Property {
            let p1 = Property (
                key: "permissionDisplayType",
                name: "Permission",
                value: p.stringVal)

            p1.toString = { (p1) in 
                return p1.plugin?.currentStatus?(p1.plugin).1?.stringVal
            }
//            p.toString = { (pp) in
//                return pp.plugin?.currentStatus?(cp: pp.plugin).1?.stringVal
//            }
            p1.toValue = { (prop, value) in
                let temp = prop
                return temp
            }
            _ = p1.freeze()
            return p1
        }
    }
}

