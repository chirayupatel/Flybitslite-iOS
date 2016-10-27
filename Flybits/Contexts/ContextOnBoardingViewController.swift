//
//  ContextOnBoardingViewController.swift
//  Flybits
//
//  Created by Archu on 2016-04-04.
//  Copyright © 2016 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
import CoreLocation
import EventKit

let kPollInterval: Int = 60 // in mins
let kUploadInterval: Int = 60 // in mins

class ContextOnBoardingViewController: UITableViewController {
    var locationManager: CLLocationManager = CLLocationManager()
    
    /*
        TODO:
        Allow context plugin to have different variables that can be set by the user (still needs some work from the app side). So user can pick how often each plugin uploads context and if possible, modify some values such as how often to get location from core location manager or set minimum distance/time on CLLocationManager.
     
        ContextPlugin class represents each different context plugin available with FlybitsSDK. Some contexts are not available on all the devices, thus, we have 'availabilityChecker' which returns true/false. For example, is CoreLocation available on the device user currently running it on?
     
        Some properties are user customizable and some has predefined value that cannot be changed by the user.
    */
    lazy var items: [ContextPlugin]! = [
        ContextPlugin(provider: .coreLocation, name: "Location Services") { (p) in
            _ = p.freeze()
            _ = p.addProperty(ContextPlugin.Property.permissionDisplayValue(CLLocationManager.authorizationStatus()))
            // p.addProperty(ContextPlugin.Property.enabled)
            
            p.availabilityChecker = { [weak self](plug) in
                let authorized:[CLAuthorizationStatus] = [.authorizedAlways, .authorizedWhenInUse, .notDetermined]
                let authorizedStatus = authorized.index(of: CLLocationManager.authorizationStatus())
                return CLLocationManager.locationServicesEnabled() && authorizedStatus != nil
            }
            p.permissionRequester = { [weak self](plug) in
                if CLLocationManager.authorizationStatus() == .authorizedAlways {
                    p.permissionSuccess?(plug)
                }
            }
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    let loc: CoreLocationDataProvider? = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval) as? CoreLocationDataProvider
                   
                    _=try? loc?.stopUpdatingLocation()
                    
                    if #available(iOS 9.0, *) {
                        loc?.allowsBackgroundLocationUpdates = true
                    }
                    _=try? loc?.requestAlwaysAuthorization()
                    
                    self?.tableView.reloadData()
                }
            }
            p.currentStatus = { [weak self](plug) in
                let authorized:[CLAuthorizationStatus] = [.authorizedAlways, .authorizedWhenInUse]
                return (authorized.index(of: CLLocationManager.authorizationStatus()) != nil, CLLocationManager.authorizationStatus())
            }
        },
        ContextPlugin(provider: .iBeacon, name: "iBeacon") { (p) in
            _ = p.addProperty(ContextPlugin.Property.permissionDisplayValue(CLLocationManager.authorizationStatus()))
            // p.addProperty(ContextPlugin.Property.enabled)
            
            p.availabilityChecker = { [weak self](plug) in
                return CLLocationManager.locationServicesEnabled() && CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)
            }
            p.permissionRequester = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    let loc = self?.locationManager
                    loc?.delegate = self
                    loc?.requestAlwaysAuthorization()
                }
            }
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    let coreloc = CoreLocationDataProvider(asCoreLocationManager: true, withRequiredAuthorization: .authorizedAlways)
                    let ibeaconOptions = Set<iBeaconDataProvider.iBeaconOptions>(arrayLiteral: .monitoring, .ranging)
                    let prov = iBeaconDataProvider(apiFrequency: kPollInterval, locationProvider: coreloc, options: ibeaconOptions)
                    prov.pollFrequency = Int32( kPollInterval )
                    prov.uploadFrequency = Int32( kPollInterval )
                    
//                    ContextManager.sharedManager.addDataForProvider(prov)
                    _ = try? ContextManager.sharedManager.register(prov)
//                    let prov = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval) as? BeaconDataProvider
                    prov.startBeaconQuery()
                    self?.tableView.reloadData()
                }
            }
            p.currentStatus = { [weak self](plug) in
                let authorized:[CLAuthorizationStatus] = [.authorizedAlways]
                return (authorized.index(of: CLLocationManager.authorizationStatus()) != nil, CLLocationManager.authorizationStatus())
            }
        },
        ContextPlugin(provider: .battery, name: "Battery status") { (p) in
            _ = p.freeze()
            UIDevice.current.isBatteryMonitoringEnabled = true
            _ = p.addProperty(ContextPlugin.Property.enabled)
            // p.addProperty(ContextPlugin.Property.pollFrequency(2 * 60))
            // p.addProperty(ContextPlugin.Property.uploadFrequency)
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    _ = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                    self?.tableView.reloadData()
                }
            }
            p.permissionSuccess?(p) // since we don't have to get permission to do this, execute it

        },
        ContextPlugin(provider: .language, name: "Device Language") { (p) in
            // p.enabled = false
            _ = p.freeze()
            _ = p.addProperty(ContextPlugin.Property.enabled)
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    _ = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                    self?.tableView.reloadData()
                }
            }
            p.permissionSuccess?(p) // since we don't have to get permission to do this, execute it

        },
        ContextPlugin(provider: .carrier, name: "Cell Network") { (p) in
            _ = p.freeze()
            // p.enabled = false
            _ = p.addProperty(ContextPlugin.Property.enabled)
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    _ = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                    self?.tableView.reloadData()
                }
            }
            p.permissionSuccess?(p) // since we don't have to get permission to do this, execute it

        },
        
        ContextPlugin(provider: .network, name: "Cell Network") { (p) in
            _ = p.freeze()
            // p.enabled = false
            _ = p.addProperty(ContextPlugin.Property.enabled)
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    _ = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                    self?.tableView.reloadData()
                }
            }
            p.permissionSuccess?(p) // since we don't have to get permission to do this, execute it
            
        },

        ContextPlugin(provider: .pedometerSteps, name: "Steps - Pedometer") { (p) in
            _ = p.freeze()
            // p.enabled = false
            _ = p.addProperty(ContextPlugin.Property.enabled)
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    _ = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                    self?.tableView.reloadData()
                }
            }
            p.permissionSuccess?(p) // since we don't have to get permission to do this, execute it
            
        },
        ContextPlugin(provider: .activity, name: "Activity") { (p) in
            _ = p.freeze()
            // p.enabled = false
            _ = p.addProperty(ContextPlugin.Property.enabled)
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    _ = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                    self?.tableView.reloadData()
                }
            }
            p.permissionSuccess?(p)
            
        },
        ContextPlugin(provider: .availability, name: "Calendar", setup: { (p) in
            p.enabled = false
            _ = p.addProperty(ContextPlugin.Property.enabled)
            _ = p.addProperty(ContextPlugin.Property.permissionDisplayValue(EKEventStore.authorizationStatus(for: EKEntityType.event)))
            p.permissionRequester = { (plug) in
                if case let status = EKEventStore.authorizationStatus(for: EKEntityType.event) , status == .notDetermined {
                    EKEventStore().requestAccess(to: EKEntityType.event, completion: { (allowed, error) in
                        print(allowed, error)
                        if allowed {
                            plug.permissionSuccess?(plug)
                        }
                    })
                } else {
                    //TODO: Show error
                }
            }
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    _ = ContextManager.sharedManager.register(p.provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                    self?.tableView.reloadData()
                }
            }
            p.currentStatus = { [weak self](plug) in
                let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
                return (status  == .authorized, status)
            }
        }),
        
        ContextPlugin(name: "Facebook", setup: { (p) in
            let facebook = LiteOAuthConsentViewController(provider: .facebook)

            p.enabled = false
            _ = p.addProperty(ContextPlugin.Property.enabled)
            p.currentStatus = { [weak self](plug) in
                if case .accepted = facebook.status {
                    return (true, PrivacyEnabledPluginPermissionType(stringVal: "name@example.com"))
                }
                return (false, facebook.status)
            }
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    self?.navigationController?.pushViewController(facebook, animated: true)
                    facebook.statusChanged = { (controller, status) in
                        if case .accepted = facebook.status {
                            _ = self?.navigationController?.popViewController(animated: true)
                        } else if case .failed(let error) = facebook.status {
                            _ = self?.navigationController?.popViewController(animated: true)
                            if let error = error {
                                let alert = UIAlertController.cancellableAlertConroller("Failed", message: error.localizedDescription, handler: nil)
                                self?.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }),
        
        ContextPlugin(name: "Spotify", setup: { (p) in
            let spotify = LiteOAuthConsentViewController(provider: .spotify)
            p.enabled = false
            _ = p.addProperty(ContextPlugin.Property.enabled)
            p.currentStatus = { [weak self](plug) in
                if case .accepted = spotify.status {
                    return (true, PrivacyEnabledPluginPermissionType(stringVal: "name@example.com"))
                }
                return (false, spotify.status)
            }
            p.permissionSuccess = { [weak self](plug) in
                OperationQueue.main.addOperation {
                    self?.navigationController?.pushViewController(spotify, animated: true)
                    spotify.statusChanged = { (controller, status) in
                        if case .accepted = spotify.status {
                            _ = self?.navigationController?.popViewController(animated: true)
                        } else if case .failed(let error) = spotify.status {
                            _ = self?.navigationController?.popViewController(animated: true)
                            if let error = error {
                                let alert = UIAlertController.cancellableAlertConroller("Failed", message: error.localizedDescription, handler: nil)
                                self?.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // since we are gonna be modifying the ContextDataProviders
        ContextManager.sharedManager.stopDataPolling()
        restoreFromPreviousConfiguration()
        let loc = self.locationManager
        loc.delegate = self
        if #available(iOS 9.0, *) {
            loc.allowsBackgroundLocationUpdates = true
        }
        loc.requestAlwaysAuthorization()

    }
    
    func saveConfiguration() {
        var contextPlugins = Array<[String: String]>()
        for plugin in self.items {
            var p = [String: String]()
            p["title"] = plugin.title
            p["enabled"] = plugin.enabled.stringVal
            if let prov = plugin.provider?.stringVal {
                p["provider"] = prov
            }
            if let poll = plugin.pollFreq(nil) {
                p["pollFreq"] = "\(poll)"
            }
            if let uploadFreq = plugin.uploadFreq(nil) {
                p["upFreq"] = "\(uploadFreq)"
            }
            
            var properties = [[String: AnyObject]]()
            for x in plugin.customisableProperties {
                var prop = [String: String]()
                prop["editable"] = x.editable.stringVal
                prop["name"] = x.name
                prop["key"] = x.key
                properties.append(prop as [String : AnyObject])
            }
            contextPlugins.append(p)
        }
        
        UserDefaults.standard.set(contextPlugins, forKey: AppConstants.UserDefaultKey.ActivatedContexts)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppConstants.UserDefaultKey.ActivatedContexts), object: nil, userInfo: nil)
        ContextManager.sharedManager.startDataPolling()
        self.dismiss(animated: true, completion: nil)
    }
    
    func restoreFromPreviousConfiguration() {
        
        let findProvider: (_ provider: ContextProvider) -> ContextPlugin? = { (p) in
            for item in self.items where item.provider == p {
                return item
            }
            return nil
        }
        
        if let objs = UserDefaults.standard.object(forKey: AppConstants.UserDefaultKey.ActivatedContexts) as? Array<[String:String]>{
            for obj in objs {
                if let prov = obj["provider"], let provider = ContextProvider.init(string: prov) {
                    let p = findProvider(provider)
                    p?.enabled = obj["enabled"]?.boolVal ?? false
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    fileprivate func findPlugin(_ provider: ContextProvider) -> ContextPlugin? {
        for plug in items where plug.provider == provider {
            return plug
        }
        return nil
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let item = items[section]
        return item.customisableProperties.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let item = items[section]
        return item.title
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let plugin = items[(indexPath as NSIndexPath).section]
        if !plugin.editable {
            return false
        }
        if plugin.enabled {
            return true
        }
        
        let property = plugin.customisableProperties[(indexPath as NSIndexPath).row]
        if property.key == "enabled" {
            return true
        }
        return property.editable
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let plugin = items[(indexPath as NSIndexPath).section]
        let property = plugin.customisableProperties[(indexPath as NSIndexPath).row]
        
        cell.textLabel?.text = property.displayString?() ?? property.toString?(property)
        cell.detailTextLabel?.text = property.name
       
        if plugin.editable && (plugin.enabled || property.key == "enabled") {
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.darkGray
            
        } else {
            cell.textLabel?.textColor = UIColor.gray
            cell.detailTextLabel?.textColor = UIColor.lightGray
            
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let plugin = items[(indexPath as NSIndexPath).section]
        
        let property = plugin.customisableProperties[(indexPath as NSIndexPath).row]
        if property.key == "enabled" {
            plugin.enabled = !plugin.enabled
            property.value = plugin.enabled
            tableView.reloadData()
        }
        
        if plugin.enabled {
            if let availability = plugin.availabilityChecker {
                if availability(plugin) {
                    if let requester = plugin.permissionRequester {
                        requester(plugin)
                    }
                }
            } else if let requester = plugin.permissionRequester , plugin.availabilityChecker == nil {
                requester(plugin)
            } else if let success = plugin.permissionSuccess , plugin.permissionRequester == nil && plugin.availabilityChecker == nil {
                success(plugin)
            }
        } else {
            if let provider = plugin.provider {
                _ = ContextManager.sharedManager.remove(provider)
            }
        }
    }
}

extension ContextOnBoardingViewController : CoreLocationDataProviderDelegate {
    func locationDataProvider(_ dataProvider: CoreLocationDataProvider, didChangeAuthorization status: CLAuthorizationStatus) {
        if Array<CLAuthorizationStatus>(arrayLiteral: .authorizedAlways, .authorizedWhenInUse).contains(status) {
            OperationQueue.main.addOperation {
                if let p = self.findPlugin(.coreLocation) {
                    p.permissionSuccess?(p)
                }
                if let p = self.findPlugin(.iBeacon) {
                    p.permissionSuccess?(p)
                }
            }
        }
    }
}

extension ContextOnBoardingViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if Array<CLAuthorizationStatus>(arrayLiteral: .authorizedAlways, .authorizedWhenInUse).contains(status) {
            OperationQueue.main.addOperation {
                if let p = self.findPlugin(.coreLocation) {
                    p.permissionSuccess?(p)
                }
                if let p = self.findPlugin(.iBeacon) {
                    p.permissionSuccess?(p)
                }
            }
        }
    }
}



// MARK: ContextPluginPermissionType

extension CLAuthorizationStatus : ContextPluginPermissionType {
    var stringVal : String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Cannot access"
        case .denied: return "Denied by user"
        case .authorizedAlways: return "Always authorized"
        case .authorizedWhenInUse: return "Available only when app in use"
        }
    }
}

extension EKAuthorizationStatus : ContextPluginPermissionType {
    var stringVal : String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Cannot access"
        case .denied: return "Denied by user"
        case .authorized: return "Authorized"
        }
    }
}
