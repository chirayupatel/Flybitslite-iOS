//
//  ViewController.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import CoreLocation
import FlybitsSDK

final class MainViewController: UIViewController, UserOnBoardDelegate, SideMenuViewControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    fileprivate var userLoggedIn = false
    fileprivate var sideMenuVC: SideMenuViewController!
    fileprivate var loginVC: UserOnBoardViewController? = nil
    fileprivate var centreVC: UIViewController?
    fileprivate var navController: MainNavController!
    
    fileprivate var constraintSideMenuLeading: NSLayoutConstraint?
    fileprivate lazy var reachability: Reachability? = { [unowned self] in
        let reachble: Reachability? = Reachability.init()
        reachble?.whenReachable = { [unowned self](reachable) in
            self.removeErrorBanner()
        }
        return reachble
    }()
    
    fileprivate lazy var dimmedView:UIView = { [unowned self] in
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(MainViewController.menuDimmedContentViewSwipped(_:)))
        swipe.direction = UISwipeGestureRecognizerDirection.left

        let view = UIView()
        view.backgroundColor = UIColor.black
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MainViewController.menuDimmedContentViewTapped(_:))))
        view.addGestureRecognizer(swipe)
        return view
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let _ = try? reachability?.startNotifier()

        let momentPush = PushMessage.NotificationType(.momentInstance, action: .custom)
        NotificationCenter.default.addObserver(forName: momentPush, object: nil, queue: nil) { [weak self](notification) -> Void in
            if let message = notification.userInfo?[PushManagerConstants.PushMessageContent] as? PushMessage {
                self?.handleNotificationMomentBroadcast(message)
            }
            print(momentPush, notification)
        }
        
        let momentZoneEntered = PushMessage.NotificationType(.momentInstance, action: .zoneEntered)
        NotificationCenter.default.addObserver(forName: momentZoneEntered, object: nil, queue: nil) { [weak self](notification) -> Void in
            print(momentZoneEntered, notification)
            if let message = notification.userInfo?[PushManagerConstants.PushMessageContent] as? PushMessage {
                self?.handleNotificationMomentBroadcast(message)
            }
        }
        
        let momentZoneExited = PushMessage.NotificationType(.momentInstance, action: .zoneExited)
        NotificationCenter.default.addObserver(forName: momentZoneExited, object: nil, queue: nil) { [weak self](notification) -> Void in
            print(momentZoneExited, notification)
            if let message = notification.userInfo?[PushManagerConstants.PushMessageContent] as? PushMessage {
                self?.handleNotificationMomentBroadcast(message)
            }
        }
        

        do { // context rules
            /* 
             
             After FlybitsSDK, successfully parses the APNs push message, it will send a broadcast message in NSNotificationCenter. Here we are going to listen for "rule updated" push message. After we get the push message from the rule, we can do whatever we want with it.
             
             Sample rule name: 
                Checkout our latest releases #Latest2016
             
             From the above rule name, we assume that 'Latest2016' is a tag, and fetch the zone with that specific tag.
             
             */
            let contextRuleUpdated = PushMessage.NotificationType(.rule, action: .ruleUpdated)
            NotificationCenter.default.addObserver(forName: contextRuleUpdated, object: nil, queue: nil) { [weak self](notification) -> Void in

                print(contextRuleUpdated, notification)
                
                if let message = notification.userInfo?[PushManagerConstants.PushMessageContent] as? PushMessage {
                    NSLog("\(message.body)")
                    self?.handleCustomRuleMessageFromRuleChange(message)
                } else {
                    NSLog("\(#function) Missing \(PushManagerConstants.PushMessageContent)")
                }
            }
        }

        if let tenantID = AppData.sharedData.appLaunchURLData?.tenantID {
            Session.sharedInstance.configuration.apiKey = tenantID
        }

        presentUserOnBoardView()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Const.App.NotificationKey.Logout), object: nil, queue: OperationQueue.main) { [weak self](n) -> Void in
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultKey.UserEmail)
                UserDefaults.standard.synchronize()
            self?.presentUserOnBoardView()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self](n) -> Void in
            self?.routeUIToSchemeURL()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "com.flybits.lite.route_to_zone_view"), object: nil, queue: OperationQueue.main) { [weak self](n) -> Void in
            self?.routeUIToSchemeURL()
        }
    }
    
    fileprivate func routeUIToSchemeURL() {
        guard self.userLoggedIn == true else { return }
        
        if Session.sharedInstance.currentUser != nil {
            self.setupContextPlugins()
        }
        
        if let data = AppData.sharedData.appLaunchURLData , Session.sharedInstance.currentUser != nil {
            _ = UserRequest.getSelf(completion: { [weak self](user, error) -> Void in
                if Utils.ErrorChecker.noInternetConnection(error) {
                    _ = self?.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                    return
                }
                if (user != nil) {
                    Session.sharedInstance.currentUser = user
                    if data.momentID != nil || data.zoneID != nil {
                        self?.presentMainView(SideMenuIdentifier.discovery)
                    }
                }
            }).execute()
        } else {
            if Session.sharedInstance.currentUser == nil {
                _ = UserRequest.getSelf(completion: { [weak self](user, error) -> Void in
                    if Utils.ErrorChecker.noInternetConnection(error) {
                        _ = self?.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                        return
                    }
                    if (user != nil) {
                        Session.sharedInstance.currentUser = user
                    }
                }).execute()
            }
        }
    }
    
    fileprivate func presentNotification(_ id:String, title: String?, body:String?, otherInfo: [String: AnyObject]?) {
        NSLog("\(#function)\(title, body)")

        guard let displayString = title ?? body else {
            NSLog("presentNotification - NOT SHOWING - title or body is nil")
            return
        }
        
        var userInfoDict = [String: AnyObject]()
        if let title = title {
            userInfoDict[kLocalNotificationUserInfoKey_Title] = title as AnyObject?
        }
        if let body = body {
            userInfoDict[kLocalNotificationUserInfoKey_Body] = body as AnyObject?
        }
        if let otherInfo = otherInfo {
            userInfoDict[kLocalNotificationUserInfoKey_OtherInfo] = otherInfo as AnyObject?
        }
        
        userInfoDict[kLocalNotificationuserInfoKey_Id] = id as AnyObject?
        
        // create a corresponding local notification
        let notification = UILocalNotification()
        
        notification.userInfo = userInfoDict
        notification.alertBody = displayString
        notification.alertAction = "Open"
        notification.fireDate = nil
        notification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    fileprivate func handleCustomRuleMessageFromRuleChange(_ message: PushMessage) {
        // get id, and ruleName out of the push message
        guard let id = message.body?["id"] as? String,
            let ruleName = message.body?["templateName"] as? String else {
            NSLog("\(#function) Missing id from \(message.body)")
            return
        }
        NSLog("\(#function) \(ruleName)")

        let semaphore = DispatchSemaphore(value: 0)
        let semaphoreAtomicAppend = DispatchSemaphore(value: 1)
        let queue = DispatchQueue.init(label: "com.flybits.lite.rule_push_handler")
        
        let hashTags = ruleName.components(separatedBy: "#")
        guard hashTags.count > 1 else { return }
        
        let strippedRuleName = hashTags.first ?? ruleName
        let hashTagsArray = hashTags.dropFirst().map {
            $0.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }
        
        // get the tag ids for all the hashtagged words from zone name
        var zoneTags = [Tag]()
        queue.async {
            // get the tagId based on the rule name
            // unfortunately, we can only search for tagValue one at a time
            for aTag in hashTagsArray {
                let query1 = TagQuery(limit: 1, offset: 0)
                query1.searchValue = aTag
                let _ = TagsRequest.query(query1) { (tags, pagination, error) in
                    if let tags = tags {
                        semaphoreAtomicAppend.wait()
                        zoneTags.append(contentsOf: tags)
                        semaphoreAtomicAppend.signal()
                    }
                    semaphore.signal()
                }.execute()
            }
            
            for _ in 0 ..< hashTagsArray.count {
                semaphore.wait()
            }
            // up to here.. we have downloaded all the tag ids.
            
            guard !zoneTags.isEmpty else {
                // if no tags found, just display the alert message
                OperationQueue.main.addOperation { [weak self] in
                    let otherInfo: [String: AnyObject] = ["sendBy": "rule" as AnyObject]
                    let displayableName = strippedRuleName.htmlDecodedString
                    self?.presentNotification(id, title: nil, body: displayableName.htmlDecodedString, otherInfo: otherInfo)
                }
                return
            }

            // now download all the zones that has all the tagIds we just fetched.
            let zoneQuery = ZonesQueryExpressions(limit: 1, offset: 0)
            zoneQuery.tagIDQuery = BooleanQuery.init(zoneTags.map { $0.identifier }, .and)
            zoneQuery.searchQuery = BooleanQuery("true:isPublished") // zone has to be a published zone
            
            let _ = ZoneRequest.query(zoneQuery) { (zones, pagination, error) in
                OperationQueue.main.addOperation { [weak self] in
                    var otherInfo: [String: AnyObject] = ["sendBy": "rule" as AnyObject]
                    if let zoneId = zones.first?.identifier {
                        // do something with this zoneId... maybe open that zone?
                        otherInfo[kLocalNotificationUserInfoKey_OtherInfoZoneID] = zoneId as AnyObject?
                    }
                    let displayableName = strippedRuleName.htmlDecodedString
                    self?.presentNotification(id, title: nil, body: displayableName.htmlDecodedString, otherInfo: otherInfo)
                }
            }.execute()
        }
    }
    
    fileprivate func handleNotificationMomentBroadcast(_ message: PushMessage) {
        OperationQueue().addOperation { [weak self] in
            
            // get the 'url' from the push message.. go download the actual content of the push message..
            // and then from that downloaded content unwrap until "localizations"
            guard let id = message.body?["id"] as? String,
                let bodyUrl = message.body?["url"] as? String,
                let bodyURLObj = URL(string: bodyUrl),
                let data = try? Data.init(contentsOf: bodyURLObj),
                let msg = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject],
                let locale = msg?["localizations"] as? [String:AnyObject]
                else {
                return
            }
            
            let otherInfo: [String: AnyObject]?
            if let zoneId = message.body?["zoneId"] as? String {
                otherInfo = [kLocalNotificationUserInfoKey_OtherInfoZoneID : zoneId as AnyObject]
            } else {
                otherInfo = nil
            }
            
            for (_, dict) in locale {
                if let obj = dict as? [String:AnyObject] {
                    let displayableMessage = obj["message"] as? String
                    let displayableName = obj["name"] as? String
                    
                    if let displayableName = displayableName?.Lite_HTMLDecodedString {
                            self?.presentNotification(id, title: displayableName, body: displayableMessage?.htmlDecodedString, otherInfo: otherInfo)
                    } else {
                        self?.presentNotification(id, title:displayableName?.htmlDecodedString, body: displayableMessage?.htmlDecodedString, otherInfo: otherInfo)
                    }
                    break;
                }
            }
        }
    }

    func presentUserOnBoardView() {
        let userOnBoard = self.storyboard!.instantiateViewController(withIdentifier: "userOnBoardVC") as! UserOnBoardViewController
        userOnBoard.delegate = self

        let oldNav = navController
        oldNav?.willMove(toParentViewController: nil)

        centreVC = nil
        sideMenuVC?.view.removeFromSuperview()
        sideMenuVC?.removeFromParentViewController()
        sideMenuVC = nil
        navController = self.storyboard?.instantiateViewController(withIdentifier: "mainNavVC") as! MainNavController
        navController.willMove(toParentViewController: self)
        view.addSubview(navController.view)
        addChildViewController(navController)

        navController.view.translatesAutoresizingMaskIntoConstraints = false
        navController.viewControllers = [userOnBoard]
        NSLayoutConstraint.equal(.height, view1: navController.view, asView: view)
        NSLayoutConstraint.equal(.top, view1: navController.view, asView: view)
        NSLayoutConstraint.equal(.width, view1: navController.view, asView: view)
        NSLayoutConstraint.equal(.leading, view1: navController.view, asView: view)
        
        
        let transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        oldNav?.view.transform = CGAffineTransform.identity
        oldNav?.view.alpha = 1
        self.navController.view.transform = transform
        self.navController.view.alpha = 0.5
        UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: { [unowned self]() -> Void in
            
            self.navController.view.transform = CGAffineTransform.identity
            oldNav?.view.transform = transform
            oldNav?.view.alpha = 0.5
            self.navController.view.alpha = 1
            
            }) { (finished) -> Void in
                oldNav?.view.alpha = 1
                oldNav?.didMove(toParentViewController: nil)
                oldNav?.removeFromParentViewController()
                oldNav?.view.removeFromSuperview()
                oldNav?.view.transform = CGAffineTransform.identity
                
                self.navController.view.alpha = 1
                self.navController.view.transform = CGAffineTransform.identity
                self.navController.didMove(toParentViewController: self)
        }

        loginVC = userOnBoard
        navController.didMove(toParentViewController: self)
    }

    func hamburgerMenuItem() -> UIBarButtonItem {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        btn.setImage(Theme.currentTheme.hamburgerMenu, for: UIControlState())
        btn.addTarget(self, action: #selector(MainViewController.hamburgerMenuTapped(_:)), for: .touchUpInside)
        return UIBarButtonItem(customView: btn)
    }

    func swippedFromLeftEdgeScreen(_ sender: UIScreenEdgePanGestureRecognizer) {
        if sender.state == .began && self.navController?.topViewController == self.centreVC {
            hamburgerMenuTapped()
        }
    }
    
    func presentMainView(_ identifier:SideMenuIdentifier? = SideMenuIdentifier.discovery) {
        self.navController?.willMove(toParentViewController: nil)
        self.navController?.view.removeFromSuperview()
        self.navController?.removeFromParentViewController()
        self.navController?.didMove(toParentViewController: nil)
        centreVC = viewControllerForIdentifier(identifier!)

        sideMenuVC = SideMenuViewController()
        sideMenuVC.delegate = self
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(MainViewController.menuSwipped(_:)))
        swipe.direction = UISwipeGestureRecognizerDirection.left
        sideMenuVC.view.addGestureRecognizer(swipe)
        sideMenuVC.selectedIdentifier = identifier
        
        navController = self.storyboard?.instantiateViewController(withIdentifier: "mainNavVC") as! MainNavController
        navController.navigationBar.backIndicatorImage = UIImage(named: "ic_back_b")
        navController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "ic_back_b")
        navController.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)

        let screen = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(swippedFromLeftEdgeScreen))
        screen.edges = .left
        screen.delegate = self
        self.navController.view?.addGestureRecognizer(screen)

        view.addSubview(navController.view)

        navController.willMove(toParentViewController: self)
        addChildViewController(navController)

        navController.view.translatesAutoresizingMaskIntoConstraints = false
        navController.pushViewController(centreVC!, animated: false)
        
        UIView.performWithoutAnimation { [unowned self]() -> Void in
            NSLayoutConstraint.equal(.height, view1: self.navController.view, asView: self.view)
            NSLayoutConstraint.equal(.top, view1: self.navController.view, asView: self.view)
            NSLayoutConstraint.equal(.width, view1: self.navController.view, asView: self.view)
        }
        
        let transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        self.navController.view.transform = transform
        self.navController.view.alpha = 0.5
        UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: { [unowned self]() -> Void in
            
            self.navController.view.transform = CGAffineTransform.identity
            self.navController.view.alpha = 1
            
            }) { (finished) -> Void in
                self.navController.view.alpha = 1
                self.navController.view.transform = CGAffineTransform.identity
                self.navController.didMove(toParentViewController: self)
                self.loginVC = nil
        }
        
        let leadingConstraint = NSLayoutConstraint(item: navController.view, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        leadingConstraint.priority = 900
        
        view.addConstraint(leadingConstraint)
        centreVC!.navigationItem.leftBarButtonItem = hamburgerMenuItem()

        assert(sideMenuVC != nil)
        sideMenuVC.loadUserProfile()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func presentContextSelectionView() {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "onboarding_context") as? ContextOnBoardingViewController {
            vc.navigationItem.rightBarButtonItem = BarButtonItem(title: "Save", callback: { (bar) in
                vc.saveConfiguration()
                vc.dismiss(animated: true, completion: nil)
            })
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }

    func hamburgerMenuTapped(_ sender:UIBarButtonItem? = nil) {
        let menuView = sideMenuVC.view
        if menuView?.superview == nil {
            openMenu()
            NotificationCenter.default.post(name: Notification.Name(rawValue: Const.App.NotificationKey.MenuWillOpen), object: nil)
            // since user interfered, cancel the launchURL way of opening pages
            AppData.sharedData.appLaunchURL = nil
        } else {
            closeMenu()
            NotificationCenter.default.post(name: Notification.Name(rawValue: Const.App.NotificationKey.MenuWillClose), object: nil)
        }
    }
    
    func menuSwipped(_ sender: UISwipeGestureRecognizer) {
        closeMenu()
    }

    func menuDimmedContentViewSwipped(_ sender: UISwipeGestureRecognizer) {
        if ((self.dimmedView.gestureRecognizers?.contains(sender)) != nil) {
            closeMenu()
        }
    }

    func menuDimmedContentViewTapped(_ sender:UIGestureRecognizer) {
        if ((self.dimmedView.gestureRecognizers?.contains(sender)) != nil) {
            closeMenu()
        }
    }

    fileprivate func openMenu() {
        let menuView = sideMenuVC.view!
        let menuWidth:CGFloat = UIScreen.main.applicationFrame.width - AppConstants.UI.MenuWidth

        self.view.addSubview(menuView)
        self.addChildViewController(sideMenuVC)
        sideMenuVC.didMove(toParentViewController: self)

        menuView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.equal(.height, view1: menuView, asView: view)
        NSLayoutConstraint.equal(.top, view1: menuView, asView: view)
        view.addConstraint(NSLayoutConstraint(item: menuView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: menuWidth))
        view.addConstraint(NSLayoutConstraint(item: navController.view, attribute: .leading, relatedBy: .equal, toItem: menuView, attribute: .trailing, multiplier: 1, constant: 0))

        let leadingConstraint = NSLayoutConstraint(item: menuView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: -menuWidth)
        view.addConstraint(leadingConstraint)
        constraintSideMenuLeading = leadingConstraint

        navController.view.addSubview(dimmedView)
        navController.view.bringSubview(toFront: navController.navigationBar)
        dimmedView.frame = self.navController.view.bounds
        dimmedView.alpha = 0
        self.view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3, animations: { [unowned self]() -> Void in
            leadingConstraint.constant = 0
            self.view.layoutIfNeeded()
            self.dimmedView.alpha = 0.8
//            self.dimmedView.frame = self.navController.view.bounds

            }, completion: { (finished) -> Void in

        }) 
        self.sideMenuVC.animationForOpening(nil)
    }

    fileprivate func closeMenu() {
        constraintSideMenuLeading?.constant = -(UIScreen.main.applicationFrame.width - AppConstants.UI.MenuWidth)

        UIView.animate(withDuration: 0.3, animations: { [weak self] () -> Void in
            self?.sideMenuVC?.animationForClosing(nil)
            self?.view.layoutIfNeeded()
            self?.dimmedView.alpha = 0.3
        }, completion: { [weak self] (finished) -> Void in
            
            self?.sideMenuVC?.willMove(toParentViewController: nil)
            self?.sideMenuVC?.view.removeFromSuperview()
            self?.sideMenuVC?.removeFromParentViewController()
            self?.sideMenuVC?.didMove(toParentViewController: nil)
            self?.dimmedView.removeFromSuperview()
        }) 
    }

    // MARK: UserOnBoardDelegate
    func userOnBoard(_ controller: UserOnBoardViewController, result: Result, viewType: UserOnBoardViewController.ViewType) {
        
        assert(Session.sharedInstance.currentUser != nil, "Current user cannot be nil")
        assert(Session.sharedInstance.currentUser?.identifier != nil, "Current userID cannot be nil")
        
        switch result {
        case .success:
            DispatchQueue.main.async { [unowned self] in
                self.userLoggedIn = true
                if let app = UIApplication.shared.delegate as? AppDelegate {
                    app.updateTokenToServer()
                    let config = PushConfiguration(serviceLevel: .both, apnsToken: nil, autoFetchData: false, autoReconnect: true)
                    config.autoSavePushPreferences = false
                    PushManager.sharedManager.configuration = config
                }
                
                self.setupContextPlugins()
                if let data = AppData.sharedData.appLaunchURLData , (data.momentID != nil || data.zoneID != nil) {
                    self.presentMainView(self.sideMenuIdentifierFromAppLaunchURL())
                } else {
                    self.presentMainView(SideMenuIdentifier.discovery)
                }
                
                // ask for push message permissions
                let mySettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
                let app = UIApplication.shared
                app.registerUserNotificationSettings(mySettings)
                app.registerForRemoteNotifications()
            }
            
        default: // UserOnBoardViewController handles all other cases -- so should never be anything other than .Success
            do {
                abort()
            }
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }

    /**
        Start all the 'enabled' context plugins so they can send data to Context engine.
    */
    fileprivate func setupContextPlugins() {
        // we have stored all the 'enabled' context plugins settings in user defaults from the first launch,
        // so let's register those plugins again so contexts are being uploaded to Flybits Context engine once app is restarted.
        if let objs = UserDefaults.standard.object(forKey: AppConstants.UserDefaultKey.ActivatedContexts) as? Array<[String:String]>{
            for obj in objs {
                if let  enabled = obj["enabled"] , enabled.boolVal {
                    if let prov = obj["provider"], let provider = ContextProvider.init(string: prov) {
                        let registeredProvider = ContextManager.sharedManager.register(provider, priority: .any, pollFrequency: kPollInterval, uploadFrequency: kUploadInterval)
                        // for iBeacon, we gotta do some customization, i.e., running it in the background
                        if provider == .iBeacon {
                            _ = registeredProvider as? iBeaconDataProvider
                            let locMang = CLLocationManager()
                            if #available(iOS 9.0, *) {
                                locMang.allowsBackgroundLocationUpdates = true
                            }
                            
                        } else if let tregisteredProvider = registeredProvider as? CoreLocationDataProvider {
                            if #available(iOS 9.0, *) {
                                tregisteredProvider.allowsBackgroundLocationUpdates = true
                            }
                            let _ = try? tregisteredProvider.startUpdatingLocation()
                        }
                    }
                }
            }
            
            // since this app depends on location, force register a location context data provider
            let coreloc = CoreLocationDataProvider(asCoreLocationManager: true, withRequiredAuthorization: .authorizedAlways)
            
            if #available(iOS 9.0, *) {
                coreloc.allowsBackgroundLocationUpdates = true
            }
            _ = try? coreloc.requestAlwaysAuthorization()
            coreloc.pollFrequency = Int32(kPollInterval)
            coreloc.uploadFrequency = Int32(kPollInterval)

            // Create and register ProprietaryDataProvider object to send custom data
            let proprietaryDataProvider = ProprietaryDataProvider.init()
            _ = try? ContextManager.sharedManager.register(proprietaryDataProvider)

            ContextManager.sharedManager.addData(for: coreloc)
            ContextManager.sharedManager.startDataPolling()
        } else {
            presentContextSelectionView()
        }
    }
    
    fileprivate func presentProfileView(_ profile:User?) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "accountSettingsVC") as? ProfileViewController {
            sideMenuVC?.selectedIdentifier = nil
            vc.user = profile
            vc.navigationItem.leftBarButtonItem = hamburgerMenuItem()
            self.navController.popToRootViewController(animated: false)
            self.centreVC?.view.removeFromSuperview()
            self.centreVC?.removeFromParentViewController()
            self.centreVC = nil
            self.navController.viewControllers = [vc]
            self.closeMenu()
        }
    }
    
    //MARK: SideMenuDelegateViewController
    func menuViewController(_ controller: SideMenuViewController, didLoadProfile:User) { }

    func menuViewController(_ controller: SideMenuViewController, didTapOnProfileView:UIView, profile:User?) {
        presentProfileView(profile)
    }

    func menuViewController(_ controller:SideMenuViewController, didSelectItem:SideMenuItemView, identifier:SideMenuIdentifier) {
        _ = presentViewController(identifier)
        ContextManager.sharedManager.startDataPolling()
    }
    
    fileprivate func presentViewController(_ identifier: SideMenuIdentifier) -> Bool {
        if let vc = viewControllerForIdentifier(identifier) {
            
            sideMenuVC?.selectedIdentifier = identifier
            
            for vc in self.navController.viewControllers {
                if let root = vc as? SideMenuable {
                    root.deactivatedFromSideMenu(self.sideMenuVC, item: sideMenuVC.getItemViewWithIdentifier(identifier)!, identifier: identifier)
                }
            }
            
            self.navController.popToRootViewController(animated: false)
            
            if let vc = vc as? SideMenuable {
                vc.activatedFromSideMenu(self.sideMenuVC, item: sideMenuVC.getItemViewWithIdentifier(identifier)!, identifier: identifier)
            }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.navController.viewControllers = [vc]
            CATransaction.commit()
            vc.navigationItem.leftBarButtonItem = hamburgerMenuItem()
            closeMenu()
            return true
        }
        return false
    }
    
    fileprivate func viewControllerForIdentifier(_ identifier: SideMenuIdentifier) -> UIViewController? {
        var vc: UIViewController! = nil
        
        switch identifier {
        case .discovery, .favourites, .myZones, .explore:
            if let zvc = storyboard?.instantiateViewController(withIdentifier: "ZonesVC") as? ZonesCollectionViewController {
                zvc.viewType = identifier.zoneViewType
                vc = zvc
            }
        case .profile:
            vc = self.storyboard?.instantiateViewController(withIdentifier: "accountSettingsVC") as? ProfileViewController
        case .logout:
            Utils.UI.presentLogoutUI(self.view.bounds, controller: self)
        }
        
        return vc
    }
    
    fileprivate func sideMenuIdentifierFromAppLaunchURL() -> SideMenuIdentifier? {
        if let data = AppData.sharedData.appLaunchURLData {
            if data.momentID != nil || data.zoneID != nil {
                return SideMenuIdentifier.discovery
            }
        }
        return nil
    }
}

extension SideMenuIdentifier {
    var zoneViewType: ZonesCollectionViewController.ViewType {
        switch self {
        case .discovery:    return ZonesCollectionViewController.ViewType.discovery
        case .myZones:      return ZonesCollectionViewController.ViewType.myZones
        case .favourites:   return ZonesCollectionViewController.ViewType.favourites
        case .explore:      return ZonesCollectionViewController.ViewType.explore
        default:            return ZonesCollectionViewController.ViewType.discovery
        }
    }
}

protocol SideMenuable {
    func activatedFromSideMenu(_ controller:SideMenuViewController, item:SideMenuItemView, identifier:SideMenuIdentifier)
    func deactivatedFromSideMenu(_ controller:SideMenuViewController, item:SideMenuItemView, identifier:SideMenuIdentifier)
}


class MainNavController : UINavigationController { }
