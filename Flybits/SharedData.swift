//
//  SharedData.swift
//  Flybits
//
//  Created by Archuthan Vijayaratnam on 11/6/15.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class AppData: NSObject {

    
    var appLaunchURLData: APPURLData?
    static let sharedData: AppData = AppData()
    var appLaunchURL: URL? {
        didSet {

            appLaunchURLData = nil

            guard let appLaunchURL = appLaunchURL?.absoluteString, let comps = URLComponents(string: appLaunchURL), let scheme = comps.scheme else {
                return
            }

            appLaunchURLData = APPURLData(scheme: scheme)
            if let qItems = comps.queryItems {
                for item in qItems where item.value != nil {
                    switch item.name.lowercased() {
                    case "zid": appLaunchURLData!.zoneID    = item.value!
                    case "mid": appLaunchURLData!.momentID  = item.value!
                    case "uid": appLaunchURLData!.userID    = item.value!
                    default: break
                    }
                }
            }
        }
    }

    // all the push topics app has subscribed -- need to resubscribe if we ever got disconnected
    var pushSubscriptions: Set<String> = Set()

    // MARK: Types
    struct APPURLData {
        init(scheme:String) {
            self.scheme = scheme
        }
        var scheme: String
        var tenantID: String?
        var zoneID: String?
        var momentID: String?
        var userID: String?
    }

    // MARK: Force-Touch & AppShortcuts
    fileprivate var launchedShortcutItem: AnyObject? // UIApplicationShortcutItem

    @available(iOS 9.0, *)
    func setLaunchedShortcut(_ item: UIApplicationShortcutItem?) {
        self.launchedShortcutItem = item
    }
    
    @available(iOS 9.0, *)
    func getLaunchedShortcut() -> UIApplicationShortcutItem? {
        return self.launchedShortcutItem as? UIApplicationShortcutItem
    }
}
