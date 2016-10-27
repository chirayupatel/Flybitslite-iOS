//
//  AppDelegate.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var pushDeviceToken: Data?
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var locationManager: CLLocationManager!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UserDefaults.standard.register(defaults: AppConstants.Configs.UserDefaultDictionary)
        
        // setup flybitssdk
        Session.sharedInstance.configuration.apiKey = "7CA85BA9-8747-446A-8436-B3C9F75C3DF2"
        Session.sharedInstance.configuration.preferredLocales = []
      
        var shouldPerformAdditionalDelegateHandling = true
       
        if let notif = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
            application.cancelLocalNotification(notif)
            shouldPerformAdditionalDelegateHandling = false
        }
        
        ContextManager.sharedManager.sentLatestValue = true
        
        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.location] {
            startSignificationLocation()
        }
        
        return shouldPerformAdditionalDelegateHandling
    }

    func startSignificationLocation() {
        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AppData.sharedData.appLaunchURL = nil
        
        if ContextManager.sharedManager.isPolling {
            startSignificationLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if UIApplication.shared.applicationState != .active {
            backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                let locationProvider = ContextManager.sharedManager.retrieve(.coreLocation) as? CoreLocationDataProvider
                locationProvider?.location = locations.last
                
                if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
                    self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
                }
            
           })
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        locationManager.stopMonitoringSignificantLocationChanges()
        if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return canOpenURL(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return canOpenURL(url)
    }
    
    fileprivate func canOpenURL(_ url:URL) -> Bool {
        AppData.sharedData.appLaunchURL = url
        if let scheme = AppData.sharedData.appLaunchURLData?.scheme , scheme.lowercased() == kFlybitsScheme.lowercased() {
            return true
        }
        AppData.sharedData.appLaunchURL = nil
        return false
    }
    
    //MARK: Push
    
    internal func updateTokenToServer() {
        guard let pushDeviceToken = self.pushDeviceToken , Session.sharedInstance.status == .connected else {
            return
        }
        
        PushManager.sharedManager.configuration.apnsToken = pushDeviceToken
        NSLog("APNS Token: \(self.pushDeviceToken)")
        NSLog("JWT Token: \(Session.sharedInstance.jwt)")
        NSLog("User ID: \(Session.sharedInstance.currentUser?.identifier)")
        NSLog("Vendor ID: \(Utilities.vendorUUID)")
        if let deviceID = Utilities.flybitsDeviceID {
            NSLog("Device Token: \(deviceID)")
        }
        NSLog("PushManager.configuration = .\(PushManager.sharedManager.configuration.serviceLevel.rawValue)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if deviceToken.count > 0 {
            self.pushDeviceToken = deviceToken
            updateTokenToServer()
        }
        NSLog("APNs Token: \(deviceToken.description.replacingOccurrences(of: " ", with: ""))")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("application:didFailToRegisterForRemoteNotificationsWithError: [\(error)]")
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
            NSLog("\(#function)\(userInfo)")
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        NSLog("\(#function)\(userInfo)")
        // Can FlybitsSDK parse this message? Then it must be from Flybits.
        // Pass in our own completion handler to PushManager, and it will be called once everything is
        // downloaded for the push message. After that callback comes back, we call the completion handler passed in 
        // by iOS to let it know that we
        if PushManager.sharedManager.received(userInfo as! [String : AnyObject], fetchCompletionHandler: { (result) in
            NSLog("\(#function)\(result)")
            
            // TODO: Register for a notification from MainViewController that should post when it displayed
            // UILocalNotification to the user. We should only call the completionHandler when we get confirmation
            // that MainViewController handled it properly instead of waiting 10 seconds.
            Delay(10) {
                completionHandler(result)
            }
        }) == false {
            completionHandler(UIBackgroundFetchResult.noData)
            NSLog("FlybitsSDK couldn't handle the PUSH Payload.")
        }
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        application.cancelLocalNotification(notification)
        
        let title = notification.userInfo?[kLocalNotificationUserInfoKey_Title] as? String
        let body = notification.userInfo?[kLocalNotificationUserInfoKey_Body] as? String
        let otherInfo = notification.userInfo?[kLocalNotificationUserInfoKey_OtherInfo] as? [String: AnyObject]
        let zoneId = otherInfo?[kLocalNotificationUserInfoKey_OtherInfoZoneID] as? String
        
        let vc = UIAlertController.alertConroller(title, message: body, setup: { (a) in
            _ = a.addDefaultDismiss(nil)
        })
        application.delegate?.window??.rootViewController?.present(vc, animated: true, completion: nil)
    }
}
