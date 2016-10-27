//
//  AppConstants.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import Foundation
import UIKit
import FlybitsSDK

struct SliderRange<T> {
    var max: T
    var min: T
    var defaultValue: T
}

func FlybitsErrorDomain(_ subdomain: String) -> String {
    return "com.flybits.\(subdomain)"
}

let kFlybitsScheme = "flybits"
let kLocalNotificationuserInfoKey_Id        = "com.flybits.lite_notification_identifier"
let kLocalNotificationUserInfoKey_Title     = "com.flybits.lite_notification_title"
let kLocalNotificationUserInfoKey_Body      = "com.flybits.lite_notification_body"
let kLocalNotificationUserInfoKey_OtherInfo = "com.flybits.lite_notification_otherinfo"
let kLocalNotificationUserInfoKey_OtherInfoZoneID = "com.flybits.lite_notification_otherinfo_zoneid"

struct Const {
    struct App {
        struct NotificationKey {
            static let Logout = "com.flybitsliteapp.logout"
            static let MenuWillOpen = "com.flybits.lite.app_menu_will_open"
            static let MenuWillClose = "com.flybits.lite.app_menu_will_close"
        }
    }
    struct FBSDK {
        struct ExceptionKey {
            static let ExceptionType = "exceptionType"
            static let ExceptionMessage = "exceptionMessage"
            static let Details = "details"
            static let FormattedError = "flybitslite_error_formatted"
        }

        struct ExceptionType {
                static let AccessDenied = "AccessDeniedException"
        }
    }
}

struct AppConstants {
    
    static var IsSimulator: Bool {
        #if os(iOS) && (arch(i386) || arch(x86_64))
            return true
        #else
            return false
        #endif
    }

    struct UI {
        static let ButtonCornerRadius = CGFloat(2)
        static let AnimationDuration: TimeInterval = 0.3
        static let MenuWidth: CGFloat = 60 // amount of view visible when side menu is open (0 = side menu takes full screen; 100 = main view is visible in last 100 points of the screen)
        static let LoadingAnimationImages: [UIImage] = {
            var imgs = [UIImage]()
            for x in 0...66 {
                let name = NSString(format: "loader_blue_000%.2d", x)
                imgs.append(UIImage(named: name as String)!)
            }
            return imgs
        }()
        
        // SideMenuViewController
        static let UserProfileBtnSize: CGSize   = CGSize(width: 100, height: 100)
        static let UserProfileHeight: CGFloat   = 140
        static let SideMenuItemHeight: CGFloat  = 40
        static let MenuIconLeading: CGFloat     = 20
        static let MenuTitleLeading: CGFloat    = 20
        static let MenuIconSize: CGSize         = CGSize(width: 20, height: 20)
        static let MenuItemHighlight: UIColor   = UIColor ( red: 0.0661, green: 0.2008, blue: 0.3616, alpha: 1.0 )
        static let MenuItemUnhighlight: UIColor = UIColor.clear
        
        static let MenuElasticSpacerViewMinHeight: CGFloat = 40
        static let MenuInterItemSpacerViewHeightMin: CGFloat = 10
        static let MenuInterItemSpacerViewHeightMax: CGFloat = 20
        
        // UserOnBoardViewController
        static let UserOnBoardBackgroundImage: UIImage = UIImage(named: "login_bg")!
        static let UserOnBoardLogoImage: UIImage = UIImage(named: "ic_logo")!
    
        static func MomentPlaceholderImage() -> UIImage {
            return UIImage(named: "ic_moment_default")!
        }

    }
    
    struct Configs {
        static let SupportTouchID = false
        // zone discovery radius
        static let ZoneDiscoveryRange = SliderRange<Float> (max: 1000.0, min: 50.0, defaultValue: 200.0)

        static let UserDefaultDictionary = [
            UserDefaultKey.ZoneDiscoveryValue : ZoneDiscoveryRange.defaultValue,
        ]
    }
    
    struct Notifications {
        static let UserProfileUpdated = "com.flybits.profile_updated"
    }
    
    struct UserDefaultKey {
        static let ZoneDiscoveryValue       = "com.flybits.zoneDiscoveryValue"
        static let ZoneOrderByPropertyName  = "com.flybits.zone_order_by_property_name"
        static let LogLatestFilePath_Debug        = "com.flybits.app_debug_filepath"
        static let UserEmail        = "com.flybits.app_current_user_email"
        static let ActivatedContexts        = "com.flybits.app_activated_contexts"
    }
    
    static func ZoneShareURL(_ zone:Zone) -> String {
        return _ZoneShareURL(zone.identifier)
    }
    
    fileprivate static  func _ZoneShareURL(_ zoneID:String) -> String {
        let str = "http://flybits.com/share/?"
//        let comp = NSURLComponents(string: str)!
//        let newString = comp.host!.stringByReplacingOccurrencesOfString("^api.", withString: (comp.scheme ?? "http") + "://", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
        let newString = str
        return newString.appendingFormat("zid=%@", zoneID)
    }
}



func Delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
