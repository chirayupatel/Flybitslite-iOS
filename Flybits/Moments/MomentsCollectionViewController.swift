//
//  MomentsViewController.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-18.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
import CoreLocation

private let kFilterUnpublishedMoments: Bool              = true
private let kMaximumMomentQueryLimit: UInt               = 50
private let kHeaderBackgroundImageVisibleHeight: CGFloat = ceil(max(100, UIScreen.main.applicationFrame.height/3.0)) // 64 or greater
private let kHeaderZoneInfoHeight: CGFloat               = 60
private let kZoneDescriptionCellHeight: CGFloat          = 60
private let kStatusBarHeight = UIApplication.shared.statusBarFrame.height
private let coreImageContext = CIContext()

// protocol conformance
extension MomentsCollectionViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate, MomentZoneInfoTitleHeaderViewDelegate, ZoneDescriptionReusableViewDelegate, MomentCollectionViewDelegateFlowLayout, ZoneMomentDisplayer, MomentZoneInfoHeaderViewDelegate { }

final class MomentsCollectionViewController: UIViewController {
    @IBOutlet weak var viewHeader: MomentBackgroundHeaderView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var zoneInfoHeaderView: MomentZoneInfoHeaderView!
    var userLocation: CLLocation?
    var locationError: NSError?
    var locationManager : CLLocationManager?
    fileprivate var isPolling = false
    fileprivate var gotMomentOnce = false
    fileprivate var gettingMoments = false {
        didSet {
            updateFooterLoadingView()
        }
    }
    
    var currentZone:Zone? {
        didSet {
            setupZoneInfo()
            subscribeToZonePush()
        }
    }
    
    var zoneID: String?
    var moments: [Moment] = []
    
    fileprivate let oprnImageDownload = OperationQueue()
    fileprivate lazy var loadingView = LoadingView()
    fileprivate var allRequests: [FlybitsRequest] = [FlybitsRequest]()
    fileprivate var currentQuery: MomentQuery?
    fileprivate var subscribedTopics: Set<String> = Set()
    fileprivate var momentAutoRun:(moment:Moment?, didAutoRun:Bool) = (nil, false)
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var zoneDescriptionExpandedHeight: CGFloat = kZoneDescriptionCellHeight
    fileprivate var infoUnderTitleHidden = false
    
    weak var currentlyOpenedMomentModule: MomentModule? {
        willSet {
            if let m = currentlyOpenedMomentModule {
                self.logDisconnectToMomentModule(m)
            }
        }
        didSet {
            if let m = currentlyOpenedMomentModule {
                self.logConnectToMomentModule(m)
            }
        }
    }

    // MARK: -- Functions
    deinit {
        allRequests.forEach {
            _ = $0.cancel()
        }
        oprnImageDownload.cancelAllOperations()
        NotificationCenter.default.removeObserver(self)
    }

    
    fileprivate func setupZoneInfo() {
        zoneInfoHeaderView?.updateName(currentZone?.name.value ?? "")
        zoneInfoHeaderView.delegate = self
        if viewHeader.useZoneImage {
            viewHeader.image = currentZone?.zoneImage(._100)?.loadedImage()
        } else {
            viewHeader?.points = currentZone?.shapes
        }
        
        if let colSubviews = self.collectionView?.subviews {
            for sub in colSubviews where sub is ZoneDescriptionReusableView {
                let reusable = sub as! ZoneDescriptionReusableView
                if reusable.zoneDescription != currentZone?.zoneDescription.value {
                    reusable.zoneDescription = currentZone?.zoneDescription.value
                    zoneDescriptionExpandedHeight = reusable.expand(reusable.expanded)
                    reusable.updateConstraintsIfNeeded()
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    break
                }
            }
        }
    }

    fileprivate func presentLoadingView() {
        loadingView.alpha = 0.0
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.fillParent(loadingView, parentView: self.view)

        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.loadingView.alpha = 1.0
        }) 
    }

    fileprivate func dismissLoadingView() {

        UIView.animate(withDuration: 0.2, animations: {
            self.loadingView.alpha = 0.0
            }, completion: { (_) in
                self.loadingView.removeFromSuperview()
                self.loadingView.alpha = 1.0
        }) 
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        statusBarBlurEffect()
        if let bar = self.navigationController?.navigationBar as? ExtendedNavigationBar {
            bar.clearNavigationBar = true
        }
        addPullToRefresh()
        setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black

        if let zoneID = zoneID {
            connectToZone(zoneID)
        } else {
            //TODO: Display Empty OR zone doesn't exists view
        }
        setupZoneInfo()
        self.title = ""
        
        NotificationCenter.default.addObserver(forName: PushManagerConstants.PushConnected, object: nil, queue: nil) { [weak self](notification) -> Void in
            print(notification)
            self?.subscribeToZonePush()
            self?.subscribedTopics.forEach({ (topic) -> () in
                PushManager.sharedManager.subscribe(to: topic)
            })
        }

        setupInitialView()
        setupBackButton()
        registerForPushMessages()
    }

    private func statusBarBlurEffect() {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light))
        blurView.frame = UIApplication.shared.statusBarFrame
        view.addSubview(blurView)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillChangeStatusBarFrame, object: nil, queue: nil) { [unowned blurView = blurView](n) in
            blurView.frame = UIApplication.shared.statusBarFrame
        }
    }
    
    private func setupInitialView() {
        if let cv = self.collectionView {
            ZoneDescriptionReusableView.registerNib(cv, kind: UICollectionElementKindHeaderReusable)
            ZoneInfoMenuCollectionReusableView.registerNib(cv, kind: UICollectionElementKindHeaderReusable)
            ZoneDescriptionReusableView.registerClass(cv, kind: UICollectionElementKindSectionHeader)
            ZoneDescriptionReusableView.registerClass(cv, kind: UICollectionElementKindSectionFooter)
            MomentLoadingFooterCollectionViewCell.registerClass(cv, kind: UICollectionElementKindSectionFooter)
        }
        
        self.collectionView.backgroundView = UIImageView()
        
        self.view.removeConstraints(viewHeader.constraints)
        self.view.removeConstraints(zoneInfoHeaderView.constraints)
        viewHeader.removeFromSuperview()
        zoneInfoHeaderView.removeFromSuperview()
        collectionView.addSubview(viewHeader)
        collectionView.addSubview(zoneInfoHeaderView)
        viewHeader.translatesAutoresizingMaskIntoConstraints = true
        zoneInfoHeaderView.translatesAutoresizingMaskIntoConstraints = true
        self.collectionView.contentInset = UIEdgeInsets(top: kHeaderBackgroundImageVisibleHeight - kHeaderZoneInfoHeight + 64 - 8, left: 0, bottom: 0, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.collectionView.contentInset.top, 0, 0, 0)

    }
    
    private func setupBackButton() {
        self.navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_back_moment")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MomentsCollectionViewController.overridenBackButton(_:)))
    }
    
    private func registerForPushMessages() {
        let momentRoleModified = PushMessage.NotificationType(.zone, action: .momentRoleModified)
        let zmiDeleted = PushMessage.NotificationType(.zoneMomentInstance, action: .deleted)
        let mDeleted = PushMessage.NotificationType(.zone, action: .momentDeleted)
        let momentModified = PushMessage.NotificationType(.zone, action: .momentModified)
        
        let ruleMomentUpdated = PushMessage.NotificationType(.zone, action: .momentRuleUpdated)
        let ruleMomAssociated = PushMessage.NotificationType(.zone, action: .momentRuleAssociated)
        let ruleMomDisassociated = PushMessage.NotificationType(.zone, action: .momentRuleDisassociated)
        
        
        _ = NotificationCenter.default.addObserver(momentRoleModified, zmiDeleted, momentModified, mDeleted, ruleMomentUpdated, ruleMomAssociated, ruleMomDisassociated) { [weak self](notification) -> Void in
            self?.getDataByPolling()
        }
    }

    func overridenBackButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
        _ = self.navigationController?.popViewController(animated: true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let m = currentlyOpenedMomentModule?.moment {
            currentlyOpenedMomentModule?.unload(m)
        }
        currentlyOpenedMomentModule = nil
        if let bar = self.navigationController?.navigationBar as? ExtendedNavigationBar {
            bar.clearNavigationBar = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let bar = self.navigationController?.navigationBar as? ExtendedNavigationBar {
            bar.clearNavigationBar = false
        }
        super.viewWillDisappear(animated)
        moments.forEach { (m) -> () in
            PushManager.sharedManager.unsubscribe(from: m)
        }
        
        if currentlyOpenedMomentModule == nil {
            NotificationCenter.default.removeObserver(self)
        }
    }

    override var preferredStatusBarStyle : UIStatusBarStyle  {
        return UIStatusBarStyle.lightContent
    }

    @IBAction func backToMomentsCollectionViewController(_ segue:UIStoryboardSegue) { }

    fileprivate func downloadZoneInfoAndUpdateView(_ id:String, completion:@escaping (_ zone:Zone?, _ error: NSError?) -> Void) {
        let req2 = ZoneRequest.getZone(identifier: id, completion: { [weak self](zone, error) -> Void in
            OperationQueue.main.addOperation {
                self?.currentZone = zone
            }
            completion(zone, error)
        }).execute()
        self.allRequests.append(req2)
    }
    
    func zoneImageUpdated(_ image: UIImage?) {
        self.setZoneImage(image)
    }
    
    fileprivate func getCurrentZoneImage() {
        if let currentZone = currentZone {
            let req = ImageRequest.download100(currentZone.image, completion: { [weak self](image, error) -> Void in
                self?.zoneImageUpdated(image)
            }).execute()
            allRequests.append(req)
        }
    }
    
    /** Get zone detail for top view and moments for bottom view **/
    fileprivate func connectToZone(_ id:String) {
        // TODO: Refactor me!
        guard !gettingMoments else { print("Already getting moments!"); return }

        presentLoadingView()

        let sema = DispatchSemaphore(value: 0)
        let queue = DispatchQueue(label: "getAndConnectToZones", attributes: [])

        gettingMoments = true
        queue.async { [weak self]() -> Void in

            guard let tempSelf = self else { return }
            
            var fetchedMoments: [Moment]?
            var error1: NSError?
            var error2: NSError?
            
            let query = MomentQuery(limit: kMaximumMomentQueryLimit, offset: 0)
            query.excludes = ["metadata"]
            query.zoneIDs = [id]
            tempSelf.currentQuery = query
            var newPagination: Pager?
            
            // download all moments
            let req1 = MomentRequest.query(query, completion: { (moments, pagination, error) -> Void in
                error1 = error
                newPagination = pagination
                fetchedMoments = kFilterUnpublishedMoments ? moments.filter({ $0.published }) : moments
                sema.signal()
            }).execute()
            tempSelf.allRequests.append(req1)

            // download zone info
            tempSelf.downloadZoneInfoAndUpdateView(id, completion: { (zone, error) -> Void in
                error2 = error
                sema.signal()
            })

            sema.wait()
            sema.wait()
            
            DispatchQueue.main.async(execute: { [weak self] in

                guard let tempSelf = self else { return }
                
                if Utils.ErrorChecker.isAccessDenied(error1) || Utils.ErrorChecker.isAccessDenied(error2) {
                    Utils.UI.takeUserToLoginPage()
                    return
                }

                if Utils.ErrorChecker.noInternetConnection(error1) || Utils.ErrorChecker.noInternetConnection(error2) {
                    tempSelf.gettingMoments = false
                    _ = tempSelf.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                    tempSelf.updateUI()
                    tempSelf.dismissLoadingView()
                    return
                }

                query.pager = newPagination!
                tempSelf.moments = fetchedMoments ?? [Moment]()
                tempSelf.updateUI()
                tempSelf.dismissLoadingView()
                
                tempSelf.moments.forEach({ 
                    PushManager.sharedManager.subscribe(to: $0)
                })

                tempSelf.getCurrentZoneImage()
                
                // check for autorun
                for moment in tempSelf.moments where moment.isAutoRun {
                    tempSelf.openMoment(moment)
                    tempSelf.momentAutoRun.didAutoRun = true
                    tempSelf.momentAutoRun.moment = moment
                    break
                }
                // start polling right after fetching moments for first time
                tempSelf.gotMomentOnce = true
                tempSelf.gettingMoments = false
            })
        }
    }
    
    fileprivate func getNextMomentsPage() {
        guard !gettingMoments else { print("Wait for previous request to comeback before getting more moments"); return }
        guard let zoneID = zoneID, let currentQuery = currentQuery else { return }
        guard let total = currentQuery.pager.total , currentQuery.pager.total != nil && currentQuery.pager.limit + currentQuery.pager.offset < total else {
            return
        }
        let query = MomentQuery(limit: currentQuery.pager.limit, offset: currentQuery.pager.offset + currentQuery.pager.limit)
        query.zoneIDs = [zoneID]
        query.excludes = ["metadata"]
        query.published = true
//        addLoadingView()
        gettingMoments = true
        let req1 = MomentRequest.query(query, completion: { [weak self](moments, pagination, error) in
            
            guard let tempSelf = self else { return }
            
            if Utils.ErrorChecker.noInternetConnection(error) {
                tempSelf.gettingMoments = false
                _ = tempSelf.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                tempSelf.updateFooterLoadingView()
                return
            }

            if Utils.ErrorChecker.isAccessDenied(error) {
                Utils.UI.takeUserToLoginPage()
                return
            }

            OperationQueue.main.addOperation {
                tempSelf.gettingMoments = false
                query.pager = pagination!
                if error == nil {
                    tempSelf.currentQuery = query
                }
                
                let fetchedMoments = kFilterUnpublishedMoments ? moments.filter({ $0.published }) : moments
                guard fetchedMoments.count > 0 else { return }
                let oldCount = tempSelf.moments.count
                tempSelf.moments.append(contentsOf: fetchedMoments)
                let newIndices = (0..<fetchedMoments.count).map({ return NSIndexPath(row: $0 + oldCount, section: 0)})
                tempSelf.collectionView.insertItems(at: newIndices as [IndexPath])
                tempSelf.updateFooterLoadingView()
                tempSelf.collectionView.collectionViewLayout.invalidateLayout()
            }
        }).execute()
        self.allRequests.append(req1)
    }

    fileprivate func updateUI() {
        self.collectionView.reloadData()
        if let _ = currentZone {
            getCurrentZoneImage()
        }
//        self.viewHeader
    }

    func unsubscribeFromPush() {
        guard let zone = self.currentZone else {
            print("no zone to unsubscribe push from...")
            return
        }

        let topic = "zone/\(zone.identifier)"
        subscribedTopics.remove(topic)
        PushManager.sharedManager.unsubscribe(from: topic)
    }

    func subscribeToZonePush() {
        guard let zone = self.currentZone else {
            print("no zone to unsubscribe push from...")
            return
        }

        // current zone related push messages
        let topic = "zone/\(zone.identifier)"
        subscribedTopics.insert(topic)
        PushManager.sharedManager.subscribe(to: topic)

        let zoneModifiedPush = PushMessage.NotificationType(.zone, action: .modified)
        NotificationCenter.default.addObserver(forName: zoneModifiedPush, object: nil, queue: nil) { [weak self](notification) -> Void in
            print(notification)
            DispatchQueue.main.async {

                if let zone = notification.userInfo?[PushManagerConstants.PushFetchedContent] as? Zone {
                    self?.zoneModified(zone)
                } else if let error = notification.userInfo?[PushManagerConstants.PushFetchError] as? NSError {
                    print(error)
                }
            }
        }
    }

    fileprivate func zoneModified(_ zone: Zone) {
        guard let currentZone = self.currentZone , currentZone.identifier == zone.identifier else {
            return
        }

        getDataByPolling()

        if zone.published != currentZone.published {
            if let _ = self.currentlyOpenedMomentModule as? UIViewController {
                _ = self.navigationController?.popToViewController(self, animated: true)
            }
        }
        if let newName = zone.name.value, let oldName = currentZone.name.value , newName != oldName {
            // name changed
            self.currentZone?.name = zone.name
            self.setupZoneInfo()
        }
        if let newDesc = zone.zoneDescription.value, let oldDesc = currentZone.zoneDescription.value ,
            newDesc != oldDesc {
                // name changed
                self.currentZone?.zoneDescription = zone.zoneDescription
                self.setupZoneInfo()
        }
        if zone.favouriteCount != currentZone.favouriteCount || abs(zone.distanceToEdge -
            currentZone.distanceToEdge) < 1.0 {
                self.setupZoneInfo()
        }
        if let newShape = zone.shapes, let oldShape = currentZone.shapes , newShape != oldShape ||
        (zone.shapes == nil || currentZone.shapes == nil){
            currentZone.shapes = zone.shapes
            self.setupZoneInfo()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // MARK: Polling
    func getDataByPolling() {
        // TODO: Refactor me!
        guard !gettingMoments else {
            //            startPolling();
            print("already getting moments -- \(#function)")
            refreshControl?.endRefreshing()
            return
        }
        guard let zoneID = zoneID, let currentQuery = currentQuery else { print("ZoneID for MomentCollectionViewController is invalid"); return }
        
        self.isPolling = true
        let query = MomentQuery(limit: currentQuery.pager.limit + currentQuery.pager.offset, offset: 0)
        query.zoneIDs = [zoneID]
        query.excludes = ["metadata"]
        _ = MomentRequest.query(query, completion: { [weak self](moments, pagination, error) -> Void in
            
            guard let tempSelf = self else { return }
            OperationQueue.main.addOperation {
                
                if Utils.ErrorChecker.isAccessDenied(error) {
                    Utils.UI.takeUserToLoginPage()
                    tempSelf.refreshControl?.endRefreshing()
                    
                    return
                }
                
                if moments.count == 0 && error != nil {
                    print("Got error while polling");
                    tempSelf.isPolling = false
                    tempSelf.refreshControl?.endRefreshing()
                    
                    return
                }
                guard !tempSelf.gettingMoments else {
                    print("already getting moments -- don't touch the UI Now");
                    tempSelf.isPolling = false
                    tempSelf.refreshControl?.endRefreshing()
                    
                    return
                }
                
                let downloadedMoments = kFilterUnpublishedMoments ? moments.filter({ $0.published }) : moments
                
                let originalSet = Set(tempSelf.moments)
                let newSet = Set(downloadedMoments)
                // 1, 2, 3
                // 3, 6
                
                let momentsAdded = newSet.subtracting(originalSet)
                let momentsRemoved = originalSet.subtracting(newSet)
                let momentsChanged = newSet.subtracting(momentsAdded).subtracting(momentsRemoved).filter({ (z1) -> Bool in
                    if let index = originalSet.index(of: z1) {
                        let z2 = originalSet[index]
                        
                        return z1.name.value != z2.name.value
                            || z1.image?.urlString() != z2.image?.urlString()
                            || z1.isAutoRun != z2.isAutoRun
                    }
                    return false
                })
                
                tempSelf.moments.append(contentsOf: momentsAdded)
                momentsRemoved.forEach({ (z) in

                    if let index = tempSelf.moments.index(of: z) {
                        tempSelf.moments.remove(at: index)
                    }
                    if let id = tempSelf.currentlyOpenedMomentModule?.moment.identifier , id == z.identifier {
                        if let _ = tempSelf.currentlyOpenedMomentModule as? UIViewController {
                            _ = tempSelf.navigationController?.popToViewController(tempSelf, animated: true)
                        }
                    }
                })
                
                /// NOTE: Moment can be made auto run... or published with autorun enabled
                
                momentsChanged.forEach { z in
                    let count = tempSelf.moments.count
                    if let index = tempSelf.moments.index(of: z) , count > 0 {
                        tempSelf.moments[index] = z
                    }
                    
                    // moment was visible before but made auto run now
                    if (tempSelf.momentAutoRun.moment == nil || tempSelf.momentAutoRun.didAutoRun == false) && z.isAutoRun {
                        tempSelf.openMoment(z)
                        tempSelf.momentAutoRun.didAutoRun = true
                        tempSelf.momentAutoRun.moment = z
                    }
                }
                
                // moment is published with autoRun enabled?
                momentsAdded.forEach { z in
                    if (tempSelf.momentAutoRun.moment == nil || tempSelf.momentAutoRun.didAutoRun == false) && z.isAutoRun {
                        tempSelf.openMoment(z)
                        tempSelf.momentAutoRun.didAutoRun = true
                        tempSelf.momentAutoRun.moment = z
                    }
                }

                if momentsAdded.count > 0 || momentsRemoved.count > 0 || momentsChanged.count > 0 {
                    tempSelf.updateUI()
                }
                tempSelf.isPolling = false
                tempSelf.refreshControl?.endRefreshing()

            }
        }).execute()
    }

    //MARK: CollectionView
    @objc(numberOfSectionsInCollectionView:)
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return moments.count
    }

    @objc(collectionView:cellForItemAtIndexPath:)
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "moments", for: indexPath) as! MomentCollectionViewCell
        let moment = moments[indexPath.row]
        cell.textLabel.text = moment.name.value
        if let oprn = cell.updateImage(moment.image) {
            oprnImageDownload.addOperation(oprn)
        }
        return cell
    }
    
    // MARK: Cells
    private func cellZoneInfoHeaderView(kind: String, indexPath: IndexPath) -> ZoneInfoMenuCollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ZoneInfoMenuCollectionReusableView.reuseID, for: indexPath) as! ZoneInfoMenuCollectionReusableView
        cell.delegate = self
        cell.updateFavouriteCount(currentZone?.favouriteCount)
        cell.updateFavouriteButton(currentZone?.favourited ?? false)
        if let coord = currentZone?.addressCoordinate, let userLocation = userLocation  {
            let zone_dist = calculate_distance(userLocation, location2:  CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            cell.btnDistance.setTitle(zone_dist, for: .normal)
        } else {
            cell.btnDistance.setTitle("Directions", for: UIControlState())
        }
        return cell
    }
    
    private func cellZoneDescriptionView(kind: String, indexPath: IndexPath) -> ZoneDescriptionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ZoneDescriptionReusableView.reuseID, for: indexPath) as! ZoneDescriptionReusableView
        cell.delegate = self
        cell.zoneDescription = currentZone?.zoneDescription.value
        return cell
    }
    
    private func cellZoneFooterView(kind: String, indexPath: IndexPath) -> MomentLoadingFooterCollectionViewCell {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MomentLoadingFooterCollectionViewCell.reuseID, for: indexPath) as! MomentLoadingFooterCollectionViewCell
        if moments.count > 0 && moments.count < 9 {
            cell.isHidden = true
        } else {
            cell.isHidden = false
        }
        let res = loadingCellStatus()
        cell.text.text = res.text
        cell.loading = res.animate
        cell.text.textColor = UIColor.white
        cell.backgroundColor = UIColor.black.withAlphaComponent(0.67)
        return cell

    }
    
    @objc(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindHeaderReusable && (indexPath as NSIndexPath).item == 0 {
            return cellZoneInfoHeaderView(kind: kind, indexPath: indexPath)
        } else if kind == UICollectionElementKindHeaderReusable {
            return cellZoneDescriptionView(kind: kind, indexPath: indexPath)
        } else if kind == UICollectionElementKindSectionHeader {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ZoneDescriptionReusableView.reuseID, for: indexPath)
            return cell
            
        } else if kind == UICollectionElementKindSectionFooter {
            return cellZoneFooterView(kind: kind, indexPath: indexPath)
        } else {
            // assert(false);
            // should never come here! but if it did, then display empty view
            let cell = UICollectionReusableView()
            cell.backgroundColor = UIColor.white
            return cell
        }
    }

    @objc(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionElementKindSectionFooter {
            getNextMomentsPage()
        }
    }
    
    @objc(collectionView:didSelectItemAtIndexPath:)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let moment = moments[indexPath.item]
        if (indexPath as NSIndexPath).section == 0 {
            openMoment(moment)
        }
    }

    fileprivate func loadingCellStatus() -> (text:String?, animate:Bool) {
        var text:String? = nil
        var animate = false
        if moments.count == 0 {
            text = "No Moments in this zone"
        } else if gettingMoments {
            text = "Loading"
            animate = true
        } else {
            text = "No more Moments"
        }
        return (text, animate)
    }
    
    fileprivate func updateFooterLoadingView() {
        var reusableView: UICollectionReusableView? = nil
        for v in self.collectionView.subviews{
            if let vv = v as? UICollectionReusableView , vv.reuseIdentifier == "LoadingFooterView" {
                reusableView = vv
                break
            }
        }
        
        guard let view = reusableView else { return }
        let res = loadingCellStatus()
        if let label = view.viewWithTag(1) as? UILabel {
            label.text = res.text
        }
        
        if let indicator = view.viewWithTag(2) as? UIActivityIndicatorView {
            if res.animate {
                indicator.startAnimating()
            } else {
                indicator.stopAnimating()
            }
        }
    }
    
    fileprivate func openMoment(_ moment:Moment) {
        print(moment.packageName)
        let aModule = LiteMomentManager.sharedManager.module(moment)

        guard let module = aModule else {
            let alert = UIAlertController.cancellableAlertConroller(nil, message: "This moment [\(moment.packageName)] is not supported right now.", handler:nil)
            self.present(alert, animated: true, completion: nil)
            return
        }

        if let module = module as? UIViewController {
            if let module = module as? MomentModule {
                currentlyOpenedMomentModule = module
            }
            navigationController?.pushViewController(module, animated: true)

        } else if type(of: module) == SpeeddialMoment.self || type(of: module) == NativeAppMoment.self { // [SpeeddialMoment.self, NativeAppMoment.self].contains(where: type(of: module).self) {

            currentlyOpenedMomentModule = module
            let dimmedLoadingView = LoadingView(frame: collectionView.frame)
            self.view.addSubview(dimmedLoadingView)
            dimmedLoadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            module.load(moment, info: self) { (data, error, otherInfo) -> Void in
                OperationQueue.main.addOperation({ () -> Void in
                    if let otherInfo = otherInfo as? [String:AnyObject] {
                        if let success = otherInfo["FlybitsReturnStatus"] as? String , success == "success" {
                            // already handled by module -- so remove the loading view
                            dimmedLoadingView.removeFromSuperview()
                            return
                        } else if let viewController = otherInfo["viewController"] as? UIViewController {
                            // Module returned us a view controller to display
                            // there might be other view controller that cannot/shouldn't be push on navigation controller
                            if viewController is UIAlertController || viewController is UINavigationController {
                                self.present(viewController, animated: true, completion: nil)
                            } else {
                                self.navigationController?.pushViewController(viewController, animated: true)
                            }
                            dimmedLoadingView.removeFromSuperview()
                        }
                    } else {
                        let momentName = moment.name.value ?? ""
                        let alert = UIAlertController.cancellableAlertConroller("Unable to load \(momentName)", message: error?.localizedDescription, handler:nil)
                        self.present(alert, animated: true, completion: nil)
                        dimmedLoadingView.removeFromSuperview()
                    }
                    self.currentlyOpenedMomentModule = nil
                })
            }
        }
    }
    
    fileprivate func logConnectToMomentModule(_ module: MomentModule) {
        _ = DeviceRequest.connect(DeviceQuery(type: .zoneMoment, identifier: module.moment.identifier)) { (error) -> Void in
        }.execute()
    }
    fileprivate func logDisconnectToMomentModule(_ module: MomentModule) {
        _ = DeviceRequest.disconnect(DeviceQuery(type: .zoneMoment, identifier: module.moment.identifier)) { (error) -> Void in
        }.execute()
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.collectionView?.reloadData()
        self.view.layoutIfNeeded()
    }

    //MARK: inherited <UIScrollViewDelegate> (from UICollectionView)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        setupStickyViewsFrame()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let rc = refreshControl {
            collectionView.bringSubview(toFront: rc)
        }
        
        setupStickyViewsFrame()
    }

    fileprivate func setupStickyViewsFrame() {
        guard let scrollView = collectionView else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        
        do {
            //background header view -- map/image
            var viewHeaderFrame = viewHeader.frame
            viewHeaderFrame.size.height = kHeaderBackgroundImageVisibleHeight
            viewHeaderFrame.size.width = collectionView.frame.size.width
            viewHeaderFrame.origin.y = -kHeaderBackgroundImageVisibleHeight
            
            if scrollView.contentOffset.y <= -scrollView.contentInset.top {
                viewHeaderFrame.origin.y =  scrollView.contentOffset.y
            } else {
                viewHeaderFrame.origin.y = -scrollView.contentInset.top
            }
            viewHeader.frame = viewHeaderFrame
        }
        
        do {
            //sticky zone name and stats at the top
            var zoneInfoHeaderFrame = zoneInfoHeaderView.frame
            zoneInfoHeaderFrame.origin.y = viewHeader.frame.maxY
            zoneInfoHeaderFrame.size.height = kHeaderZoneInfoHeight
            zoneInfoHeaderFrame.size.width = collectionView.frame.size.width
            
            // make zone name view sticky at the top
            if scrollView.contentOffset.y >= viewHeader.frame.maxY {
                zoneInfoHeaderFrame.origin.y =  scrollView.contentOffset.y
                zoneInfoHeaderFrame.size.height = max(kHeaderZoneInfoHeight, kHeaderZoneInfoHeight + viewHeader.frame.maxY - scrollView.contentOffset.y)
            }
            zoneInfoHeaderView.frame = zoneInfoHeaderFrame

            viewHeader.isHidden = scrollView.contentOffset.y >= viewHeader.frame.maxY
            
        }

        CATransaction.commit()
    }


    fileprivate func setZoneImage(_ image:UIImage?) {
        viewHeader.image = image
        guard let imgView = self.collectionView.backgroundView as? UIImageView else { return }
        
        imgView.image = UIImage.image(UIColor.lightGray, size: CGSize(width: 2, height: 2))
        guard let image = image else { return }
        
        OperationQueue().addOperation { [weak self] in
            
            guard let input = CIImage(image: image) else { return }
            
            let transform = CGAffineTransform(scaleX: 20.0/max(image.size.width, 0.1), y: 20.0/max(image.size.height, 0.1))
            let inputImg: CIImage = input.applying(transform)
            
            let blurredImage = CIFilter(name: "CIGammaAdjust", withInputParameters: [kCIInputImageKey:inputImg, "inputPower":0.9])?.outputImage
            let blurredImage1 = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius":4, kCIInputImageKey: blurredImage ?? inputImg])?.outputImage
            
            if let newImg = coreImageContext.createCGImage(blurredImage1 ?? inputImg, from: inputImg.extent) {
                let newImage: UIImage = UIImage(cgImage: newImg)
                
                OperationQueue.main.addOperation({
                    if let img = self?.collectionView.backgroundView as? UIImageView {
                        img.image = newImage
                    }
                })
            }
        }
    }
}

// MARK: <MomentZoneInfoHeaderViewDelegate>
extension MomentsCollectionViewController {
    func momentZoneInfoHeaderView(_ view: ZoneInfoMenuCollectionReusableView, tappedButton: UIButton, type: ZoneInfoMenuCollectionReusableView.ButtonType) {

        guard let currentZone = currentZone else { print("\(self), current zone is nil"); return }

        switch type {
        case .distance:
            currentZone.lite_openExternalMap({ (success) -> Void in
                if !success {
                    //TODO: Display error
                }
            })

        case .favourite:
            
            if let view = tappedButton as? ButtonSizableImage {
                view.loading = true
            }

            let original = !(currentZone.favourited)
            currentZone.lite_favourite(original, completion: { [weak view](success, error) -> Void in
                if success {
                    view?.updateFavouriteButton(original)
                    view?.updateFavouriteCount(currentZone.favouriteCount)
                }
                if let view = tappedButton as? ButtonSizableImage {
                    view.loading = false
                }
            })

        case .share:
            let activity = currentZone.lite_share()
            present(activity, animated: true, completion: nil)
        }
    }


    // MARK: internal LocationManagerStuff
    internal func startLocationManager() {
        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        locationManager?.delegate = self
        locationManager?.distanceFilter = CLLocationDistance(50)

        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }

    internal func stopLocationManager() {
        locationManager?.stopUpdatingLocation()
    }

}

// MARK: <CLLocationManagerDelegate>
extension MomentsCollectionViewController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.first
        self.locationError = nil
        setupZoneInfo()
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationError = error as NSError?
    }

    func calculate_distance(_ location1: CLLocation, location2: CLLocation) -> String {
        let dist = location2.distance(from: location1)
        return Utils.Formatter.ZoneDistance(Float(dist))
    }
}

// MARK: <ZoneMomentDisplayer>
extension MomentsCollectionViewController {
    func zoneRemoved(_ controller: ZonesCollectionViewController, zone:Zone, reason: ZoneMomentUnavailableReason) {

        switch reason {
        case .inaccessible(let reason):
            _ = self.displayErrorMessage(reason)
        default:
            _ = self.displayErrorMessage("Zone is unavailable")
        }
        
        Delay(1.0) {
            if let _ = self.presentingViewController {
                self.dismiss(animated: true, completion: nil)
            } else {
                _ = self.navigationController?.popToViewController(self, animated: true)
                _ = self.navigationController?.popViewController(animated: true)
            }
            self.removeErrorBanner()
        }
    }
    
    func zoneUpdated(_ controller: ZonesCollectionViewController, zone:Zone) {
        // zone got updated, download the zone again -- for zone shape.
        downloadZoneInfoAndUpdateView(zone.identifier) { (downloadedZone, error) -> Void in
            self.currentZone = downloadedZone ?? zone
            self.getCurrentZoneImage()
        }
    }
}

// MARK: <MomentCollectionViewDelegateFlowLayout>
extension MomentsCollectionViewController {
    func collectionView(_ collectionViewLayout: MomentCollectionViewFlowLayout, collectionViewHeaderSizeForIndexPath indexPath: IndexPath, kind: String) -> CGSize {
        
        if (indexPath as NSIndexPath).item == 1 { // zoneInfoMenu
            return CGSize(width: 0, height: zoneDescriptionExpandedHeight)
        }
        return CGSize(width: 0, height: 40)
    }
    
    func collectionView(_ collectionViewLayout: MomentCollectionViewFlowLayout, referenceHeaderSizeForIndexPath indexPath: IndexPath, kind: String) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionViewLayout: MomentCollectionViewFlowLayout, referenceFooterSizeForIndexPath indexPath: IndexPath, kind: String) -> CGSize {
        return CGSize(width: 0, height: 40)
    }
    
    func collectionViewNumberOfReusableHeaderViews(_ collectionViewLayout: MomentCollectionViewFlowLayout) -> Int {
        return self.infoUnderTitleHidden ? 2 : 0
    }
}

// MARK: <ZoneDescriptionReusableViewDelegate>
extension MomentsCollectionViewController {
    func zoneDescriptionReusableView(_ view: ZoneDescriptionReusableView, tappedMoreButton: UIButton) {
        zoneDescriptionExpandedHeight = view.toggleDescriptionHeight()
        view.updateConstraintsIfNeeded()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: <MomentZoneInfoTitleHeaderViewDelegate>
extension MomentsCollectionViewController {
    func infoTitleHeaderView(_ view: MomentZoneInfoHeaderView, didTapButton: UIButton?) {
        self.infoUnderTitleHidden = !self.infoUnderTitleHidden
        let layout = self.collectionView.collectionViewLayout as! MomentCollectionViewFlowLayout
        layout.invalidateLayout() // re-query for self.infoUnderTitleHidden when laying out again
    }
}

internal extension MomentsCollectionViewController {
    /// MARK: PullToRefresh
    func addPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.darkGray
        refreshControl?.addTarget(self, action: #selector(MomentsCollectionViewController.refreshControlActivated(_:)), for: UIControlEvents.valueChanged)
        self.collectionView?.addSubview(refreshControl!)
        self.collectionView?.alwaysBounceVertical = true
    }
    
    func refreshControlActivated(_ sender: UIRefreshControl) {
        self.getDataByPolling()
    }
}


class ZoneDescriptionInvalidationContext: UICollectionViewLayoutInvalidationContext {
    var invalidateSectionHeaders = false
    var shouldInvalidateEverything = false
    override var invalidatedSupplementaryIndexPaths: [String : [IndexPath]] {
        return [UICollectionElementKindHeaderReusable : [IndexPath(item: 1, section: 0)]]
    }
}
