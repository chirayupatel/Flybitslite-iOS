//
//  ZonesCollectionViewController.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-13.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
import CoreLocation
import MapKit

private let UseAutolayoutCell: Bool = true
private let ZonePageLimit:UInt = 10
private let kDefaultSearchString = "true:isPublished"
private let kDefaultZoneExcludeProperties = ["zoneMomentInstanceIds", "managerIds", "timeZone", "createdAt", "lastModifiedAt", "metadata", "shapes", "roleIds"]

private enum SortTitle : String {
    case popular    = "Popular"
    case nearby     = "Nearby"
//    case Rating = "Rating"
    case name       = "A-Z"
    
    var searchQueryName: String {
        switch self {
        case .popular:  return "popularity"
        case .nearby:   return "distance"
//        case .Rating: return "rating"
        case .name:     return "name"
        }
    }
    
    static func sortTitleForQueryName(_ queryName:String) -> SortTitle? {
        switch queryName.lowercased() {
        case "popularity": return .popular
        case "distance": return .nearby
//        case "rating": return .Rating
        case "name": return .name
        default: return nil
        }
    }
}

private enum LoadingStatus {
    case loading
    case noZones
    case noMoreZones
    case waitingForLocation
    case error(NSError)
    case done
}

final class ZonesCollectionViewController: UICollectionViewController, CLLocationManagerDelegate, ZoneCollectionViewCellDelegate, FilterViewDelegate {

    enum ViewType {
        case discovery
        case myZones
        case favourites
        case explore
        case usersZone

        var title:String {
            switch self {
            case .discovery:    return NSLocalizedString("SIDEMENU_TITLE_ZONE_DISCOVERY", comment: "Side menu 'Zone Discovery' title")
            case .myZones:      return NSLocalizedString("SIDEMENU_TITLE_MY_ZONES", comment: "Side menu 'My Own Zones' title")
            case .favourites:   return NSLocalizedString("SIDEMENU_TITLE_FAVOURITES", comment: "Side menu 'Favourites' title")
            case .explore:      return NSLocalizedString("SIDEMENU_TITLE_EXPLORE", comment: "Side menu 'Explore' title")
            case .usersZone:    return NSLocalizedString("SIDEMENU_TITLE_USERS_ZONE", comment: "Side menu 'Users Zone' title")
            }
        }
    }

    var zones: [Zone]                    = []
    var tags: [String: VisibleTag]              = [:]
    var zoneOwners: [String: User]              = [:]
    
    @IBOutlet weak var barButtonSearch: UIBarButtonItem!
    @IBOutlet weak var barButtonFilter: UIBarButtonItem!
    
    fileprivate var locationManager: CLLocationManager? = nil
    fileprivate var errors: NSError?                    = nil
    fileprivate var _locationError: NSError?
    fileprivate var locationError: NSError? {
        get {
            if viewType == ViewType.discovery {
                return _locationError
            } else {
                return nil
            }
        }
        set (value) {
            self._locationError = value
        }
    }
    fileprivate var userLocation: CLLocation?
    fileprivate var waitingForLocation: Bool            = false {
        didSet {
            if waitingForLocation {
                startLocationManager()
            }
        }
    }

    fileprivate var gettingZones: Bool                  = false
    fileprivate var gettingZonesNeedLocation: Bool      = false

    var viewType: ViewType                          = .discovery
    var query: ZonesQueryExpressions?               = nil

    fileprivate let imageCache = NSCache<NSString, UIImage>.init()
    fileprivate let context : CIContext                  = CIContext()
    
    fileprivate var searchView: UISearchBar?            = nil
    fileprivate var isSearchViewChangedContent          = false
    
    fileprivate var didWakeUpFromBackground             = false // reload view when the app comes from background -- since Foreground push is disabled
    
    fileprivate lazy var filterView: FilterView = self.createFilterView()
    fileprivate lazy var filterViewConstraints: [NSLayoutConstraint] = self.createFilterViewConstraints()
    fileprivate var emptyView: ImagedEmptyView = ImagedEmptyView()
    
    var querySetupCallback:((_ query: ZonesQueryExpressions) -> ZonesQueryExpressions)? = nil
    
    fileprivate var currentRequest: FlybitsRequest? = nil {
        willSet {
            _ = currentRequest?.cancel()
        }
    }
    fileprivate var imageDownloadQueue: OperationQueue!
    fileprivate var networkQueue: OperationQueue!
    var refreshControl: UIRefreshControl?

    fileprivate var isPolling = false
    weak fileprivate var momentViewController: MomentsCollectionViewController? { // ZoneMomentDisplayer
        willSet {
            if let zID = momentViewController?.zoneID {
                self.logDisconnectToZone(zID)
            }
        }
        didSet {
            if let zID = momentViewController?.zoneID {
                self.logConnectToZone(zID)
            }
        }
    }
    fileprivate lazy var reachability: Reachability? = { [weak self] in
        let reachble: Reachability? = Reachability.init()
        reachble?.whenReachable = { [weak self] (reachable) in
            if let error = self?.errors , Utils.ErrorChecker.noInternetConnection(error) && self?.collectionView != nil && self?.zones.count == 0{
                OperationQueue.main.addOperation { [weak self] in
                    self?.query?.pager = Pager(limit: ZonePageLimit, offset: 0)
                    self?.getDataByPolling()
                }
            }
        }
        return reachble
    }()
    
    
    deinit {
        imageDownloadQueue?.cancelAllOperations()
        networkQueue?.cancelAllOperations()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addPullToRefresh()
        
        barButtonSearch.image = Theme.currentTheme.zoneViewSearchBarButtonImage
        barButtonFilter.image = Theme.currentTheme.zoneViewFilterBarButtonImage
        navigationItem.rightBarButtonItems = [barButtonSearch, barButtonFilter]
        
        filterView.arrowBackgroundView.backgroundColor = Theme.currentTheme.zoneViewFilterBackgroundColor
        filterView.arrowImage = Theme.currentTheme.zoneViewFilterArrowImage
        
        // Do any additional setup after loading the view.
        subscribeToPush()
        self.title = viewType.title
        imageDownloadQueue = OperationQueue()
        imageDownloadQueue.name = "com.flybitslite.zoneimageprocessing"
        imageDownloadQueue.qualityOfService = QualityOfService.userInteractive
        
        networkQueue = OperationQueue()
        networkQueue.name = "com.flybitslite.zonenetworkprocessing"
        networkQueue.qualityOfService = QualityOfService.userInteractive
        
        query = getQuery(viewType).query
        currentRequest = getZonesForCurrentViewType(completion: completionOfGetZones)
        
        if let layout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: view.frame.size.width, height: view.frame.size.width * (view.frame.size.width > 600 ? 0.5 : 0.75))
        }
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        if #available(iOS 9.0, *) {
            registerForPreviewing(with: self, sourceView: collectionView!)
        }

        if let zoneID = AppData.sharedData.appLaunchURLData?.zoneID  {
            let destin = self.storyboard!.instantiateViewController(withIdentifier: "momentsVC") as! MomentsCollectionViewController
            destin.zoneID = zoneID
            momentViewController = destin
            self.navigationController?.pushViewController(destin, animated: true)
            AppData.sharedData.appLaunchURL = nil

//            if AppData.sharedData.appLaunchURLData?.momentID == nil {
//                // since momentID is nil, we don't need to keep the URL anymore for
//                // forwarding the path
//                AppData.sharedData.appLaunchURLData = nil
//            }
            
        } /* else if let momentID = AppData.sharedData.appLaunchURLData?.momentID {
            // 1. Get the detail of moment ( to find zoneID )
            // 2. Load the Zone
            // 3. Open the zone and then the moment
        } */
        
        // Keyboard setup for Search view
        self.collectionView?.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil) { [weak self](n) -> Void in
            self?.keyboardFrameModifiedNoification(n, hide:false)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil) { [weak self](n) -> Void in
            self?.keyboardFrameModifiedNoification(n, hide:true)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil, queue: nil) { [weak self](n) -> Void in
            self?.keyboardFrameModifiedNoification(n, hide:false)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil) { [weak self](n) in
            self?.didWakeUpFromBackground = true
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self](n) -> Void in
            // just woke up from background -- so fetch again
            if let tempself = self , tempself.didWakeUpFromBackground {
                OperationQueue.main.addOperation {
                    tempself.query?.pager = Pager(limit: ZonePageLimit, offset: 0)
                    tempself.getDataByPolling()
                }
            }
            self?.didWakeUpFromBackground = false
        }

        // Hamburger Menu
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Const.App.NotificationKey.MenuWillOpen), object: nil, queue: nil) { [weak self](n) -> Void in
            self?.view.endEditing(true)
            self?.searchView?.resignFirstResponder()
        }
    }

    fileprivate func keyboardFrameModifiedNoification(_ n:Notification, hide:Bool) {
        
        if let frameValue = ((n as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let animCurve = ((n as NSNotification).userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue,
            let animDur = ((n as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue {
                
                UIView.animate(withDuration: animDur,
                    delay: 0,
                    options: UIViewAnimationOptions(rawValue: animCurve),
                    animations: { [unowned self]() -> Void in
                        
                        if hide {
                            self.collectionView?.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0)
                            self.collectionView?.scrollIndicatorInsets = self.collectionView?.contentInset ?? UIEdgeInsets.zero
                        } else {
                            if #available(iOS 9.0, *) {
                                self.collectionView?.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0)
                                self.collectionView?.scrollIndicatorInsets = self.collectionView?.contentInset ?? UIEdgeInsets.zero
                            } else {
                                self.collectionView?.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, frameValue.height, 0)
                                self.collectionView?.scrollIndicatorInsets = self.collectionView?.contentInset ?? UIEdgeInsets.zero
                            }
                        }
                    }, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.removeErrorBanner()
        self.momentViewController = nil
        if gettingZonesNeedLocation {
            startLocationManager()
        }
        let _=try? reachability?.startNotifier()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability?.stopNotifier()
        stopLocationManager()
        if self.momentViewController == nil {
            self.unsubscribeFromPush()
        }
    }

    override func viewDidLayoutSubviews() {
        if searchView?.isFirstResponder == true {
            if let cv = self.collectionView {
                var rect = self.view.frame
                rect.size.height = rect.height - cv.contentInset.bottom
                self.emptyView.frame = rect
                return
            }
        }
        self.emptyView.frame = self.view.bounds
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageDownloadQueue.cancelAllOperations()
    }
    
    fileprivate func reloadCollectionViewData() {
        if zones.count == 0 {
            let status = getLoadingStatus()
            switch status {
            case .done, .noMoreZones, .noZones:
                self.displayEmptyView()
            default:
                self.removeEmptyView()
            }
        } else {
            self.removeEmptyView()
        }
        self.collectionView?.reloadData()
        refreshControl?.endRefreshing()
    }
    
    lazy var completionOfGetZones:(_ query:ZonesQueryExpressions, _ zones:[Zone]?, _ paging:Pager?, _ error:NSError?) -> Void = { [weak self](query, zones, paging, error) in
        
        precondition(Thread.main == Thread.current, "\(#function) called on different thread: \(Thread.callStackSymbols)")
        print("Number of zones receieved : \(zones?.count ?? 0)")
        
        guard let tempSelf = self else { return }
        tempSelf.errors = error
        if let zones = zones {
            if let paging = paging {
                tempSelf.query?.pager = paging
            }
            tempSelf.zones.append(contentsOf: zones)
            tempSelf.subscribeToZonePush(zones) // subscribe to push for the new zones
            
            var indexPaths = [NSIndexPath]()

            if tempSelf.viewType == .explore || tempSelf.viewType == .usersZone {
                tempSelf.getAdditionalZoneData()
            }
            
            let oldCount = tempSelf.zones.count - zones.count
            var changed: Bool = false
            for x in 0..<zones.count {
                indexPaths.append(NSIndexPath(item: oldCount + x, section: 0))
                changed = true
            }
            
            if (tempSelf.zones.count == zones.count) || tempSelf.searchView != nil {
                tempSelf.reloadCollectionViewData()
            } else {
                if changed {
                    UIView.performWithoutAnimation {
                        tempSelf.collectionView?.insertItems(at: indexPaths as [IndexPath])
                        tempSelf.removeEmptyView()
                    }
                }
            }
            tempSelf.gettingZones = false
            
        } else {
            tempSelf.gettingZones = false
            //TODO: display error
            print("Zones query: \(query)")
            print("Error: \(error)")
        }
    }
    
    func getAdditionalZoneData() {
        if zones.count == 0 {
            return
        }
        do { //tags
            var tags = Set<String>()
            for z in zones where z.tagIDs != nil {
                tags.formUnion(Set<String>(z.tagIDs!))
            }
            self.getTags(tags.map({$0}))
        }
        
        do { //users
            var owners = Set<String>()
            for z in zones where !z.creatorId.isEmpty {
                owners.insert(z.creatorId)
            }
            self.getUsers(owners.map({$0}))
        }
        
        
    }
    
    @nonobjc
    func getUsers(_ users: [String]) {
        
        let userQuery = UsersQuery(limit: 500, offset: 0)
        userQuery.userIDs = users
        userQuery.excludes = ["deviceIds", "activeUserRelationship", "metadata", "lastModifiedAt", "createdAt"]
        _ = UserRequest.getUsers(userQuery) { (users, pager, error) in
            
            OperationQueue.main.addOperation {
                for u in users {
                    self.zoneOwners[u.identifier] = u
                }
                // reload zones when at least one of the zone has a tag
                if let cell = self.collectionView?.visibleCells as? [ZoneCollectionViewCell] {
                    for c in cell where c.zoneObject != nil {
                        self.updateCell(c, zone: c.zoneObject)
                    }
                }
            }
        }.execute()
    }

    @nonobjc
    func getTags(_ tags: [String]) {
        
        let tagQuery = TagQuery(limit: 500, offset: 0)
        tagQuery.tagIDs = tags
        tagQuery.excludes = ["zoneIds", "zoneMomentInstanceIds"]
        _ = TagsRequest.query(tagQuery) { (tags: [VisibleTag]?, pagination, error) in
            OperationQueue.main.addOperation({
                if let tags = tags {
                    for t in tags {
                        self.tags[t.identifier] = t
                    }
                }
                
                
                // reload zones when at least one of the zone has a tag
                if let cell = self.collectionView?.visibleCells as? [ZoneCollectionViewCell] {
                    for c in cell where c.zoneObject?.tagIDs != nil && !(c.zoneObject!.tagIDs!.isEmpty) {
                        self.updateCell(c, zone: c.zoneObject)
                    }
                }
            })
        }.execute()
    }
    
    
    @nonobjc // when push is receieved, this function is invoked to get the latest changes
    func getDataByPolling() {
        
        guard let query = self.query , isPolling == false else {
            return
        }
        self.isPolling = true
        
        query.pager = Pager(limit: query.pager.limit + query.pager.offset, offset: 0, countRecords: 0)
        _ = ZoneRequest.query(query, completion: { [weak self](zones, pagination, error) -> Void in
            
            guard let tempSelf = self else { return }
            
            if Utils.ErrorChecker.isAccessDenied(error) {
                Utils.UI.takeUserToLoginPage()
                tempSelf.isPolling = false
                return
            }
            
            guard error == nil else {
                tempSelf.isPolling = false
                return
            }
            
            let originalSet = Set(tempSelf.zones)
            let newSet = Set(zones)
            // 1, 2, 3
            // 3, 6
            
            let additions = newSet.subtracting(originalSet)
            let removals = originalSet.subtracting(newSet)
            var tempChanges = newSet.subtracting(additions)
            tempChanges.subtract(removals)
            
            let changes = tempChanges.filter({ (z1) -> Bool in
                if let index = originalSet.index(of: z1) {
                    let z2 = originalSet[index]
                    
                    return z1.name.value != z2.name.value
                        || z1.zoneDescription.value != z2.zoneDescription.value
                        || z1.distanceToEdge - z2.distanceToEdge > 0.00001
                        || z1.favourited != z2.favourited
                        || z1.favouriteCount != z2.favouriteCount
                        || z1.image.urlString() != z2.image.urlString()
                }
                return false
            })
            
            
            var tags = Set<String>()
            for z in zones where z.tagIDs != nil {
                tags.formUnion(Set<String>(z.tagIDs!))
            }
            tempSelf.getTags(tags.map({$0}))
            
            OperationQueue.main.addOperation { [weak self] in
                guard let tempSelf = self else { return }

                let zoneID = tempSelf.momentViewController?.zoneID ?? ""

                // unsubscribe from push for removed moments
                tempSelf.unsubscribeFromZonePush(removals.flatMap({ return $0 }))
                
                tempSelf.subscribeToZonePush(zones.flatMap({ return $0 }))
                
                for z in removals {
                    if let index = tempSelf.zones.index(of: z) {
                        tempSelf.zones.remove(at: index)
                    
                        if z.identifier == zoneID {
                            tempSelf.momentViewController?.zoneRemoved(tempSelf, zone: z, reason: ZoneMomentUnavailableReason.inaccessible(reason: NSLocalizedString("ZONEVIEW_ZONE_IS_INACCESSIBLE", comment: "")))
                        }
                    }
                }
                for z in changes {
                    let count = tempSelf.zones.count
                    if let index = tempSelf.zones.index(of: z) , count > 0 {
                        let oldZone = tempSelf.zones[index]
                        tempSelf.zones[index] = z
                        
                        if z.identifier == zoneID {
                            tempSelf.momentViewController?.zoneUpdated(tempSelf, zone: z)
                        }
                        
                        if oldZone.image.urlString() != z.image.urlString() {
                            // only if the icon is different, remove the cache -- don't download Zone image if it hasn't been changed.
                            tempSelf.imageCache.removeObject(forKey: "\(z.identifier)" as NSString)
                        }
                    }
                }
                if let page = pagination {
                    query.pager = Pager(limit: page.limit, offset: 0, countRecords: page.total)
                }
                tempSelf.zones = zones
                tempSelf.errors = error
                tempSelf.reloadCollectionViewData()
                tempSelf.isPolling = false
            }
        }).execute()
    }

    fileprivate func unsubscribeFromPush() {
        let modified = PushMessage.NotificationType(.zone, action: .modified)
        let created = PushMessage.NotificationType(.zone, action: .created)
        let removed = PushMessage.NotificationType(.zone, action: .deleted)
        let entered = PushMessage.NotificationType(.zone, action: .entered)
        let exited = PushMessage.NotificationType(.zone, action: .exited)
        let roleModified = PushMessage.NotificationType(.zone, action: .roleModified)

        let ruleUpdated = PushMessage.NotificationType(.zone, action: .ruleUpdated)
        let ruleAssociated = PushMessage.NotificationType(.zone, action: .ruleAssociated)
        let ruleDisassociated = PushMessage.NotificationType(.zone, action: .ruleDisassociated)
        
        let ruleMomentUpdated = PushMessage.NotificationType(.zone, action: .momentRuleUpdated)
        let ruleMomAssociated = PushMessage.NotificationType(.zone, action: .momentRuleAssociated)
        let ruleMomDisassociated = PushMessage.NotificationType(.zone, action: .momentRuleDisassociated)

        NotificationCenter.default.removeObservers(self, names: modified, created, removed, entered, exited, roleModified, ruleUpdated, ruleAssociated, ruleDisassociated, ruleMomentUpdated, ruleMomAssociated, ruleMomDisassociated)
    }
    override var canBecomeFirstResponder : Bool {
        return true
    }

    fileprivate func subscribeToPush() {

        let modified = PushMessage.NotificationType(.zone, action: .modified)
        let created = PushMessage.NotificationType(.zone, action: .created)
        let removed = PushMessage.NotificationType(.zone, action: .deleted)

        let entered = PushMessage.NotificationType(.zone, action: .entered)
        let exited = PushMessage.NotificationType(.zone, action: .exited)
        
        let roleModified = PushMessage.NotificationType(.zone, action: .roleModified)

        let ruleUpdated = PushMessage.NotificationType(.zone, action: .ruleUpdated)
        let ruleAssociated = PushMessage.NotificationType(.zone, action: .ruleAssociated)
        let ruleDisassociated = PushMessage.NotificationType(.zone, action: .ruleDisassociated)
        
        let ruleMomentUpdated = PushMessage.NotificationType(.zone, action: .momentRuleUpdated)
        let ruleMomAssociated = PushMessage.NotificationType(.zone, action: .momentRuleAssociated)
        let ruleMomDisassociated = PushMessage.NotificationType(.zone, action: .momentRuleDisassociated)

        _ = NotificationCenter.default.addObserver(modified, created, removed, entered, exited, roleModified, ruleUpdated, ruleAssociated, ruleDisassociated, ruleMomentUpdated, ruleMomAssociated, ruleMomDisassociated) { [weak self](notification) -> Void in
            
            guard let tempSelf = self else { return }
            NSLog("Notification = \(tempSelf) \(notification)")
            
            if notification.name == modified {
                
                if let pushedZone = notification.userInfo?[PushManagerConstants.PushFetchedContent] as? Zone , pushedZone.published == false {
                    tempSelf.momentViewController?.zoneRemoved(tempSelf, zone: pushedZone, reason: ZoneMomentUnavailableReason.inaccessible(reason: NSLocalizedString("ZONEVIEW_ZONE_IS_INACCESSIBLE", comment: "")))
                    return
                }
            }
            self?.getDataByPolling()
        }
    }

    fileprivate func subscribeToZonePush(_ zones:[Zone]) {
        for zone in zones {
            // current zone related push messages
            zone.subscribeToPush()
        }
    }
    fileprivate func unsubscribeFromZonePush(_ zones:[Zone]) {
        for zone in zones {
            // current zone related push messages
            zone.unsubscribeFromPush()
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return zones.count
    }
    fileprivate func nameFromIndexPath(_ index:IndexPath) -> String {
        return "\((index as NSIndexPath).section)-\((index as NSIndexPath).row)"
    }

    fileprivate func zoneDistance(_ zone: Zone) -> String {
        if let userCoord = query?.location , CLLocationCoordinate2DIsValid(zone.addressCoordinate) {
            let zoneCoord = zone.addressCoordinate
            let zoneLoc = CLLocation(latitude: zoneCoord.latitude, longitude: zoneCoord.longitude)
            let userLoc = CLLocation(latitude: userCoord.coordinate.latitude, longitude: userCoord.coordinate.longitude)
            
            let dist = Utils.Formatter.ZoneDistance(Float(userLoc.distance(from: zoneLoc)))
            return dist
        } else {
            let dist = zone.distanceToEdge.sign == FloatingPointSign.minus ? "" : Utils.Formatter.ZoneDistance(zone.distanceToCenter)
            return dist
        }
    }
    
    fileprivate func updateCell(_ cell: ZoneCollectionViewCell, zone: Zone) {
        if let cell = cell as? ZoneDetailedInfoCollectionViewCell {
            var tagObjs: [Tag] = []
            if let tags = zone.tagIDs , !tags.isEmpty {
                let tagObjects = tags.flatMap({ self.tags[$0] })
                tagObjs = tagObjects
            }
            var owner: User? = nil
            if !zone.creatorId.isEmpty {
                owner = self.zoneOwners[zone.creatorId]
            }
            let img = self.imageCache.object(forKey: zone.creatorId as NSString)
            if let indexPath = self.collectionView?.indexPath(for: cell) , img == nil {
                downloadUserImage(indexPath)
            }
            cell.updateUI(tagObjs, owner: owner, userImage: img ?? owner?.profile?.image?.loadedImage(forSize: ._20, for: nil))
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let zone = zones[indexPath.row]
        let cell: ZoneCollectionViewCell
        
        if !(viewType == .explore || viewType == .usersZone) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZoneCollectionViewCell.reuseID, for: indexPath) as! ZoneCollectionViewCell
        } else {
            let tempCell = collectionView.dequeueReusableCell(withReuseIdentifier: ZoneDetailedInfoCollectionViewCell.reuseID, for: indexPath) as! ZoneDetailedInfoCollectionViewCell
            cell = tempCell
        }
        cell.layer.rasterizationScale = UIScreen.main.scale
        cell.layer.shouldRasterize = true
        cell.setup(zone, index: indexPath, zoneDistance: zoneDistance(zone), locale: nil)
        cell.delegate = collectionView.delegate as? ZoneCollectionViewCellDelegate
        setZoneImage(indexPath, zone: zone, size:cell.imgZoneView.bounds.size)
        updateCell(cell, zone: zone)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionFooter {

            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "LoadingCell", for: indexPath)
            cell.backgroundColor = UIColor.gray
            if let label = cell.viewWithTag(2) as? UILabel, let indicator = cell.viewWithTag(1) as? UIActivityIndicatorView {
                indicator.startAnimating()
                cell.isHidden = false
                
                let status = getLoadingStatus()
                switch status {
                case .error(let e):
                    
                    if Utils.ErrorChecker.noInternetConnection(e) {
                        cell.backgroundColor = UIColor.red
                        label.text = NSLocalizedString("NO_INTERNET_CONNECTION", comment: "")
                    } else {
                        label.text = e.localizedDescription
                    }
                    indicator.stopAnimating()

                case .waitingForLocation:
                    label.text = NSLocalizedString("LOCATION_SERVICE_FINDING_DEVICE_LOCATION", comment: "")
                
                case .noMoreZones where zones.count > 2:
                    if let total = query?.pager.total {
                        label.text = "Found \(total) Zone(s)"
                    } else {
                        label.text = NSLocalizedString("ZONEVIEW_PAGING_NO_MORE_ZONES", comment: "")
                    }
                    indicator.stopAnimating()
                
                case .noZones:
                    label.text = NSLocalizedString("ZONEVIEW_FOOTER_VIEW_EMPTY", comment: "")
                    indicator.stopAnimating()
                
                case .loading where zones.count > 0: // loading while no zones
                    break
                
                case .loading: // loading to get next page
                    label.text = NSLocalizedString("ZONEVIEW_FOOTER_VIEW_LOADING", comment: "")
                
                case .done:
                    fallthrough
                
                default:
                    cell.isHidden = true
                }
            }
            return cell
        }
        return UICollectionReusableView()
    }

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        performSegue(withIdentifier: "zone_cell_tapped", sender: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let query = query, let total = query.pager.total , zones.count - 1 == indexPath.item && total > query.pager.offset + query.pager.limit {
            currentRequest = getZonesForCurrentViewType(true, completion: completionOfGetZones)
        }
        
        downloadUserImage(indexPath)
    }

    fileprivate func downloadUserImage(_ indexPath: IndexPath) {
        let zone = self.zones[indexPath.item]
        let user = self.zoneOwners[zone.creatorId]
        
        self.imageDownloadQueue.addOperation {
            if let user = user {
                if let _ = self.imageCache.object(forKey: user.identifier as NSString) {
                    OperationQueue.main.addOperation { [weak self] in
                        guard let c = self?.collectionView?.cellForItem(at: indexPath) as? ZoneCollectionViewCell else { return }
                        self?.updateCell(c, zone: zone)
                    }
                } else if let image = user.profile?.image {
                    _ = image.loadImage(forSize: ._20, for: nil) { (image, error) in
                        OperationQueue.main.addOperation { [weak self] in
                            if let img = image.loadedImage(forSize: ._20, for: nil) {
                                self?.imageCache.setObject(img, forKey: user.identifier as NSString)
                                
                                guard let c = self?.collectionView?.cellForItem(at: indexPath) as? ZoneDetailedInfoCollectionViewCell else { return }
                                self?.updateCell(c, zone: zone)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setZoneImage(_ indexPath:IndexPath, zone:Zone, size:CGSize) {
        self.imageDownloadQueue.addOperation { [weak self, weak imageCache, weak zone] in
            if let zoneID = zone?.identifier, let img = imageCache?.object(forKey: "\(zoneID)" as NSString) {
                OperationQueue.main.addOperation { [weak self] in
                    guard let c = self?.collectionView?.cellForItem(at: indexPath) as? ZoneCollectionViewCell else { return }
                    c.setImage(img)
                }
            } else {
                let size = zone!.image.smallestBestFittingSizeForSize(viewSize: size, locale: nil)
                _ = ImageRequest.download(zone!.image, nil, size) { [weak self](image, error) in
                    if let img = image, let zoneID = zone?.identifier {
                        OperationQueue.main.addOperation { [weak self] in
                            imageCache?.setObject(img, forKey: "\(zoneID)" as NSString)
                            guard let c = self?.collectionView?.cellForItem(at: indexPath) as? ZoneCollectionViewCell else { return }
                            c.setImage(img)
                            
                            if zoneID == self?.momentViewController?.zoneID {
                                self?.momentViewController?.zoneImageUpdated(img)
                            }
                        }
                    }
                }.execute()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if case let identifier = segue.identifier , identifier == "zone_cell_tapped" {
            if let destin = segue.destination as? MomentsCollectionViewController, let zone = sender as? Zone {
                destin.zoneID = zone.identifier
                momentViewController = destin
            }
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    fileprivate func logConnectToZone(_ zoneID: String) {
        _ = DeviceRequest.connect(DeviceQuery(type: .zone, identifier: zoneID)) { (error) -> Void in
        }.execute()
    }
    fileprivate func logDisconnectToZone(_ zoneID: String) {
        _ = DeviceRequest.disconnect(DeviceQuery(type: .zone, identifier: zoneID)) { (error) -> Void in
        }.execute()
    }

    
    //Empty View
    func displayEmptyView() {
        if emptyView.superview == nil {
//            emptyView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyView)
            
//            NSLayoutConstraint.equal(.CenterX, view1: emptyView, asView: view)
//            NSLayoutConstraint.equal(.CenterY, view1: emptyView, asView: view)
//            NSLayoutConstraint.equal(.Width, view1: emptyView, asView: view)
//            NSLayoutConstraint.equal(.Height, view1: emptyView, asView: view)
            
            emptyView.updateImage(UIImage(named: "ic_logo"))
        }
        
        if searchView?.superview != nil {
            emptyView.updateLabel(NSLocalizedString("ZONEVIEW_EMPTY_TITLE_SEARCH_VIEW", comment: "No Zones found"))
        } else {
            switch viewType {
            case .discovery:
                emptyView.updateLabel(NSLocalizedString("ZONEVIEW_EMPTY_TITLE_DISCOVERY", comment: "Empty Zone Discovery"))
            case .favourites:
                emptyView.updateLabel(NSLocalizedString("ZONEVIEW_EMPTY_TITLE_FAVOURITES", comment: "Empty Zone Discovery"))
            case .myZones:
                emptyView.updateLabel(NSLocalizedString("ZONEVIEW_EMPTY_TITLE_MYZONES", comment: "Empty Zone Discovery"))
            case .explore:
                emptyView.updateLabel(NSLocalizedString("ZONEVIEW_EMPTY_TITLE_EXPLORE", comment: "Empty Zone Explore page"))
            case .usersZone:
                emptyView.updateLabel(NSLocalizedString("ZONEVIEW_EMPTY_TITLE_EXPLORE", comment: "Empty Zone Explore page"))
            }
        }
    }
    
    func removeEmptyView() {
        emptyView.removeFromSuperview()
    }

    //FilterView
    fileprivate func showFilterView(_ arrowPoint:CGPoint) {
        filterView.arrowImageOrigin = arrowPoint
        self.view.addSubview(filterView)
        NSLayoutConstraint.activate(filterViewConstraints)
    }

    fileprivate func hideFilterView() {
        NSLayoutConstraint.deactivate(filterViewConstraints)
        filterView.removeFromSuperview()
    }

    @IBAction func filterDisplayButtonTapped(_ sender: UIBarButtonItem, event:UIEvent) {
        searchView?.resignFirstResponder()
        if filterView.superview != nil {
            hideFilterView()
        } else {
            let p = event.touches(for: self.view.window!)?.first!
            if let btn = p?.view {
                showFilterView(CGPoint(x: btn.frame.midX, y: btn.frame.midY))
                switch viewType {
                case .favourites, .myZones, .explore, .usersZone:
                    filterView.items = [SortTitle.popular.rawValue, /*  SortTitle.Nearby.rawValue, SortTitle.Rating.rawValue, */ SortTitle.name.rawValue]
                case .discovery:
                    filterView.items = [SortTitle.popular.rawValue, SortTitle.nearby.rawValue, /* SortTitle.Rating.rawValue, */ SortTitle.name.rawValue]
                }

            } else {
                showFilterView(CGPoint.zero)
//                print("Shouldn't come here!!!")
            }
        }
    }

    @IBAction func searchDisplayButtonTapped(_ sender: UIBarButtonItem) {
        self.emptyView.removeFromSuperview()
        
        // remove search view if it was already visible
        guard searchView?.superview == nil else {
            self.navigationItem.titleView = nil
            self.title = viewType.title
            removeSearchView()
            self.searchView?.removeFromSuperview()
            self.searchView = nil
            if isSearchViewChangedContent {
                self.fetchContentAgain()
            }
            isSearchViewChangedContent = false
            return
        }
        
        hideFilterView()
        
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        searchBar.delegate = self
        searchBar.barStyle = UIBarStyle.black
        searchBar.searchBarStyle = UISearchBarStyle.minimal
        searchBar.placeholder = "Search"
        searchBar.becomeFirstResponder()
        searchBar.sizeToFit()
        searchBar.alpha = 0
        self.navigationItem.titleView = searchBar
        self.searchView = searchBar
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.searchView?.alpha = 1
        }) 
    }


    //MARK: Network Calls
    fileprivate func getQuery(_ type:ViewType) -> (query:ZonesQueryExpressions?, error:NSError?) {
        assert(Session.sharedInstance.currentUser != nil, "Current user cannot be nil")
        assert(Session.sharedInstance.currentUser?.identifier != nil, "Current userID cannot be nil")

        var query = ZonesQueryExpressions(limit:ZonePageLimit, offset: 0)
        query.excludes = kDefaultZoneExcludeProperties
        
        switch type {
        case .discovery:
            if userLocation == nil {
                waitingForLocation = true
                return (nil, NSError(domain: "FLB", code: 100, userInfo: [NSLocalizedDescriptionKey:"Waiting for location"]))
            }
            query.location = userLocation
            let def = UserDefaults.standard
            if let value = def.value(forKey: AppConstants.UserDefaultKey.ZoneDiscoveryValue) as? NSNumber {
                query.distance = CLLocationDistance( value.floatValue )
            } else {
                query.distance = CLLocationDistance( AppConstants.Configs.ZoneDiscoveryRange.defaultValue)
            }
        case .myZones:
            query.userIDs = ["\(Session.sharedInstance.currentUser!.identifier)"]

        case .favourites:
            query.favourites = true
        case .explore:
            do { }
        case .usersZone:
            do { }
            
        }
        query.searchQuery = BooleanQuery("true:isPublished")
        query.search = kDefaultSearchString
        query.orderBy = UserDefaults.standard.object(forKey: AppConstants.UserDefaultKey.ZoneOrderByPropertyName) as? String
        
        if let querySetupCallback = querySetupCallback {
            query = querySetupCallback(query)
        }
        return (query, nil)
    }

    fileprivate func getZonesForCurrentViewType(_ more:Bool = false, completion:@escaping (_ query:ZonesQueryExpressions, _ zones:[Zone]?, _ paging:Pager?, _ error:NSError?) -> Void) -> FlybitsRequest? {
//        print("\(#function)")

        guard gettingZones == false else { print("Already getZone is in progress"); return nil }
        guard let query = self.query else { print("Zone query cannot be nil"); return nil }

        gettingZones = true

        if case .discovery = viewType {
            gettingZonesNeedLocation = true
        } else {
            gettingZonesNeedLocation = false
        }

        if more {
            self.query = query.nextPage()
        }
        
        return _getZones(query, searchString: nil, completion: { [weak self](query, zones, paging, error) -> Void in
                self?.gettingZones = false
            completion(query, zones, paging, error)
        })
    }

    fileprivate func _getZones(_ query:ZonesQueryExpressions, searchString:String?, completion:@escaping (_ query:ZonesQueryExpressions, _ zones:[Zone]?, _ paging:Pager?, _ error:NSError?) -> Void) -> FlybitsRequest? {
        var request: FlybitsRequest?
        
        networkQueue.addOperation {
            request = ZoneRequest.query(query, completion: { (zones, pagination, error) -> Void in
                if Utils.ErrorChecker.isAccessDenied(error) {
                    Utils.UI.takeUserToLoginPage()
                    return
                }

                OperationQueue.main.addOperation {
                    completion(query, zones, pagination, error)
                }
            }).execute()
        }
        return request
    }

    //MARK: ZoneCollectionViewCellDelegate
    func zoneCollectionViewCellDidSelect(_ cell:ZoneCollectionViewCell, indexPath:IndexPath, userInfo:AnyObject?) {
        let zone: Zone
        
        if let tempZone = userInfo as? Zone {
            zone = tempZone
        } else {
            zone = zones[indexPath.row]
        }
        
        let destin = self.storyboard!.instantiateViewController(withIdentifier: "momentsVC") as! MomentsCollectionViewController
        destin.zoneID = zone.identifier
        momentViewController = destin
        self.searchView?.resignFirstResponder()
        self.navigationController?.pushViewController(destin, animated: true)
    }

    func zoneCollectionViewCell(_ cell:ZoneCollectionViewCell, didTapOnView:UIView, type:ZoneCollectionViewCell.ButtonType, indexPath:IndexPath, userInfo:AnyObject?) {

        guard (indexPath as NSIndexPath).row >= 0 && indexPath.row < zones.count else { return }
        
        let zone = zones[indexPath.row]

        switch type {
        case .distance:
            zone.lite_openExternalMap({ (success) -> Void in
                if !success {
                    //TODO: Display error
                }
            })


        case .favourite:
            if let view = didTapOnView as? ButtonSizableImage {
                view.loading = true
            }

            let newValue = !zone.favourited
            zone.lite_favourite(newValue, completion: { [weak self](success, error) -> Void in
                
                if success {
                    OperationQueue.main.addOperation {
                        if let cell = self?.collectionView?.cellForItem(at: indexPath) as? ZoneCollectionViewCell {
                            cell.favourited = zone.favourited
                            cell.setNumOfFavourite(zone.favouriteCount)
                        }
                        if let view = didTapOnView as? ButtonSizableImage {
                            view.loading = false
                        }
                    }
                } else {
                    //TODO: Display error
                }
                
            })

        case .share:
            let activity = zone.lite_share()
            present(activity, animated: true, completion: nil)
        
        case .none:
            // UserProfile tapped
            if let _ = cell as? ZoneDetailedInfoCollectionViewCell {
                
                if let p = self.storyboard?.instantiateViewController(withIdentifier: "userprofilevc") as? UserProfileViewController {
                p.user = zoneOwners[zone.creatorId]
                self.navigationController?.pushViewController(p, animated: true)
                }
            }
            break
        }
    }

    //MARK: FilterViewDelegate
    func filterViewDidCancel(_ view:FilterView) {
        hideFilterView()
    }

    func filterView(_ view:FilterView, didSelectItem item:String, index:Int, sortOrder:SortOrder) {
       
        let def = UserDefaults.standard
        
        let sortItem = SortTitle(rawValue: item)!
        query?.pager = Pager(limit: ZonePageLimit, offset: 0, countRecords: 0)

        if let oldValue = def.object(forKey: AppConstants.UserDefaultKey.ZoneOrderByPropertyName) as? String , sortItem.searchQueryName == oldValue {
            view.selectedItem = nil
            query?.orderBy = nil
            def.removeObject(forKey: AppConstants.UserDefaultKey.ZoneOrderByPropertyName)
        } else {
            query?.orderBy = sortItem.searchQueryName
            def.set(sortItem.searchQueryName, forKey: AppConstants.UserDefaultKey.ZoneOrderByPropertyName)
        }
        def.synchronize()
        
        currentRequest = getZonesForCurrentViewType(false, completion: completionOfGetZones)
        zones.removeAll()
        self.reloadCollectionViewData()
        hideFilterView()
    }

    func filterView(_ view:FilterView, didDeselectItem item:String, index:Int, sortOrder:SortOrder) { }
}

// MARK: - SearchBar Delegations
extension ZonesCollectionViewController : UISearchBarDelegate {

    func getSearchResults() {
        isSearchViewChangedContent = true
        let controller = self// nav.viewControllers.first! as! ZonesCollectionViewController
        assert(self == controller)
        controller.imageDownloadQueue.cancelAllOperations()
        controller.networkQueue.cancelAllOperations()
        _ = controller.currentRequest?.cancel()
        controller.currentRequest = nil

        let whitespaceCharacterSet = CharacterSet.whitespaces
        if let strippedString = searchView?.text?.trimmingCharacters(in: whitespaceCharacterSet).lowercased() , !strippedString.isEmpty {
            controller.query?.searchQuery = BooleanQuery("true:isPublished").and("\(strippedString):name;description")
        } else {
            controller.query?.search = kDefaultSearchString
            controller.query?.searchQuery = nil
        }

        controller.query?.excludes = kDefaultZoneExcludeProperties
        controller.query?.pager = Pager(limit: ZonePageLimit, offset: 0)
        _ = controller.getZonesForCurrentViewType(completion: completionOfGetZones)
        controller.zones = [Zone]()
        controller.reloadCollectionViewData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        getSearchResults()
        searchView?.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        getSearchResults()
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        removeSearchView()
        self.fetchContentAgain()
    }
    
    fileprivate func removeSearchView() {
        let controller = self
        controller.query?.search = kDefaultSearchString
        controller.query?.searchQuery = nil
        controller.zones = [Zone]()
        controller.reloadCollectionViewData()
        searchView?.resignFirstResponder()
    }
    
    fileprivate func fetchContentAgain() {
        _ = getZonesForCurrentViewType(false, completion: completionOfGetZones)
        self.reloadCollectionViewData()
    }
}

// MARK: - FilterView Creation
extension ZonesCollectionViewController {
    func createFilterView() -> FilterView {
        let fv = FilterView()
        fv.items = [SortTitle.popular.rawValue, SortTitle.nearby.rawValue, /* SortTitle.Rating.rawValue, */ SortTitle.name.rawValue]
        fv.ascendingImage = Selectable<UIImage>(normal: UIImage(named:"ic_ascending_list_unselected_b"), selected: UIImage(named:"ic_ascending_list_w"))
        fv.descendingImage = Selectable<UIImage>(normal: UIImage(named:"ic_descending_list_unselected_b"), selected: UIImage(named:"ic_descending_list_w"))
        fv.itemTextColor = Selectable<UIColor>(normal: UIColor.white, selected: UIColor.primaryButtonColor())
        fv.itemBackgroundColor = Selectable<UIColor>(normal: UIColor.clear, selected: UIColor.white)
        fv.contentBackgroundColor = Theme.secondary.viewBackgroundColor
        fv.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        fv.translatesAutoresizingMaskIntoConstraints = false
        fv.delegate = self
        //        fv.heightConstraintMultiplier = 0.5
        
        if let str = UserDefaults.standard.object(forKey: AppConstants.UserDefaultKey.ZoneOrderByPropertyName) as? String,
            let sortOrderItem = SortTitle.sortTitleForQueryName(str),
            let index = fv.items.index(of: sortOrderItem.rawValue){
                fv.selectedItem = (sortOrderItem.rawValue, index)
        }
        return fv
    }
    
    func createFilterViewConstraints() -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        
        constraints.append(NSLayoutConstraint(item: filterView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: filterView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: filterView, attribute: .height, relatedBy: .equal, toItem: self.view, attribute: .height, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: filterView, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0))
        
        return constraints
        
    }
}

//MARK: LocationManagerStuff
extension ZonesCollectionViewController {
    func startLocationManager() {
        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        locationManager?.delegate = self
//        locationManager?.requestAlwaysAuthorization()
        if #available(iOS 9.0, *) {
            locationManager?.allowsBackgroundLocationUpdates = true
        }
        locationManager?.startUpdatingLocation()
    }
    
    func stopLocationManager() {
        locationManager?.stopUpdatingLocation()
    }
    
    //MARK: LocationManagerDelegates
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //TODO: - Should remove this!!
        let error1 = error as NSError
        if error1.code == 0 && error1.domain == kCLErrorDomain {
            locationError = NSError(domain: kCLErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("UNABLE_TO_FIX_USER_LOCATION", comment: "")])
        } else {
            locationError = error as NSError?
        }
        self.reloadCollectionViewData()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let update:()->Void = {
            self.userLocation = locations.last!
            if self.waitingForLocation {
                self.waitingForLocation = false
                
                self.query = self.getQuery(self.viewType).query
                self.query?.pager = Pager(limit: ZonePageLimit, offset: 0)
                self.currentRequest = self.getZonesForCurrentViewType(completion: self.completionOfGetZones)
                self.reloadCollectionViewData()
            }
        }
        
        if let userLoc = userLocation , zones.count == 0 || userLoc.distance(from: locations.last!) > CLLocationDistance(100) {
            update()
        } else if userLocation == nil {
            update()
        }
    }
}

extension ZonesCollectionViewController : UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = self.collectionView?.indexPathForItem(at: location),
            let cell = self.collectionView?.cellForItem(at: indexPath) else { return nil }
        
        // Create a detail view controller and set its properties.
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "momentsVC") as? MomentsCollectionViewController else { return nil }
        
        let zone = self.zones[indexPath.item]
        detailViewController.zoneID = zone.identifier
        detailViewController.title = zone.name.value

        /*
        Set the height of the preview by setting the preferred content size of the detail view controller.
        Width should be zero, because it's not used in portrait.
        */
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: self.view.frame.height - 100)
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        if #available(iOS 9.0, *) {
            previewingContext.sourceRect = cell.frame
        }
        return detailViewController
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        show(viewControllerToCommit, sender: self)
    }

}

private extension ZonesCollectionViewController {
    func getLoadingStatus() -> LoadingStatus {
        if waitingForLocation && (errors?.localizedDescription != nil || locationError?.localizedDescription != nil){
            return LoadingStatus.error(errors ?? locationError!)
        } else if waitingForLocation {
            return LoadingStatus.waitingForLocation
        } else if gettingZones {
            return LoadingStatus.loading
        } else if let error = errors {
                return LoadingStatus.error(Utils.ErrorChecker.formatError(error))
        } else {
            if self.zones.count == 0 {
                return LoadingStatus.noZones
            } else {
                return LoadingStatus.noMoreZones
            }
        }
    }
}

internal extension ZonesCollectionViewController {
    /// MARK: PullToRefresh
    func addPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(ZonesCollectionViewController.refreshControlActivated(_:)), for: UIControlEvents.valueChanged)
        self.collectionView?.addSubview(refreshControl!)
        self.collectionView?.alwaysBounceVertical = true
    }
    
    func refreshControlActivated(_ sender: UIRefreshControl) {
        self.getDataByPolling()
    }
}

enum ZoneMomentUnavailableReason {
    case unknown
    case inaccessible(reason:String)
}

protocol ZoneMomentDisplayer : class {
    var zoneID: String? { get }
    func zoneRemoved(_ controller: ZonesCollectionViewController, zone:Zone, reason: ZoneMomentUnavailableReason)
    func zoneUpdated(_ controller: ZonesCollectionViewController, zone:Zone)
}


extension ZonesCollectionViewController : SideMenuable {
    func activatedFromSideMenu(_ controller:SideMenuViewController, item:SideMenuItemView, identifier:SideMenuIdentifier) { }
    func deactivatedFromSideMenu(_ controller:SideMenuViewController, item:SideMenuItemView, identifier:SideMenuIdentifier) {
        self.unsubscribeFromPush()
    }
}
