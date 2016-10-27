//
//  UsersMomentCollectionViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-17.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

private let reuseIdentifierCellList = "CellList"
private let reuseIdentifierCellCard = "CellCard"

open class UsersMomentCollectionViewController: UICollectionViewController, MomentModule, UserListCollectionViewDelegate {

    open var moment:Moment!
    fileprivate var data: UsersMomentData?
    fileprivate var imageQ: OperationQueue = OperationQueue()
    open class var CurrentLocaleCode: String {
        return (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String ?? "EN"
    }

    fileprivate var listLayout: UICollectionViewLayout {
        let layout = UserListCollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.itemSize = CGSize(width: self.collectionView!.frame.width, height: 120)
        layout.minimumLineSpacing = 10
        return layout
    }

    public required init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder, moment:Moment) {
        self.moment = moment
        super.init(coder: aDecoder)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        collectionView?.setCollectionViewLayout(self.listLayout, animated: true)

        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        self.title = moment.name.value
        self.navigationItem.rightBarButtonItem = nil

        // Do any additional setup after loading the view.
        _ = moment.validate({ [weak self](success, error) in
            if success {
                self?.loadData(dimmedLoadingView)
            } else {
                print(error)
                OperationQueue.main.addOperation {
                    let alert = UIAlertController.cancellableAlertConroller("Validation Failed", message: error?.localizedDescription, handler: nil)
                    self?.present(alert, animated: true, completion: nil)

                    dimmedLoadingView.removeFromSuperview()
                }
            }
        })
    }

    func loadData(_ loadingView:UIView?) {
        
        _ = UserMomentRequest.getUsers(moment: self.moment, allLocales: true) { (data, error) -> Void in
            defer {
                OperationQueue.main.addOperation {
                    loadingView?.removeFromSuperview()
                }
            }
            OperationQueue.main.addOperation { () -> Void in
                self.data = data
                self.collectionView?.reloadData()
                
                guard let data = data , data.items.count > 0 else {
                    let alert = UIAlertController.cancellableAlertConroller("Empty Data", message: "No users found", handler: nil)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
            }

        }.execute()
    }

    open func initialize(_ moment:Moment) {
        self.moment = moment
    }

    public func load(_ moment: Moment, info: AnyObject?) {
        load(moment, info: info, completion: nil)
    }

    public func load(_ moment: Moment, info: AnyObject?, completion: ((Data?, NSError?, NSDictionary?) -> Void)?) {
        self.moment = moment
    }

    open func unload(_ moment:Moment) {
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data?.items.count ?? 0
    }

    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var cell: UserListCollectionBaseCellView

        if collectionView.collectionViewLayout is UserListCollectionViewFlowLayout {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierCellList, for: indexPath) as! UserListItemViewCollectionViewCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierCellCard, for: indexPath) as! UserListCardItemView
        }
        cell.delegate = self

        if let item = data?.items[(indexPath as NSIndexPath).item], let currentItem = item.preferredLocalizedItem(UsersMomentCollectionViewController.CurrentLocaleCode) {
            cell.titleLabel.text = currentItem.fullname
            cell.subtitleLabel.text = currentItem.position ?? currentItem.email ?? ""

            cell.btnSocialFacebook.isHidden = currentItem.facebookUrl == nil
            cell.btnSocialTwitter.isHidden = currentItem.twitterUrl == nil
            cell.btnSocialInstagram.isHidden = currentItem.instagramUrl == nil
//            cell.btnSocialLinkedIn?.hidden = true
//
//            cell.btnSocialFacebook.enabled = currentItem.facebookUrl != nil
//            cell.btnSocialLinkedIn.enabled = false
//            cell.btnSocialTwitter.enabled = currentItem.twitterUrl != nil

            if let imgURL = item.imageUrl {
                imageQ.addOperation(cell.setImage(imgURL))
            }
        }
        
        // Configure the cell
        return cell
    }

    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destin = segue.destination as? UserListDetailViewController, let sender = sender as? UsersMomentCollectionViewController.UsersMomentData.DataItem  , segue.identifier == "detail" {
            destin.item = sender
        }
        super.prepare(for: segue, sender: sender)
    }

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        performSegue(withIdentifier: "detail", sender: data?.items[(indexPath as NSIndexPath).item])
    }
    
    func collectionViewCell(_ cell:UICollectionViewCell, didTapOnButton:UIButton, item: UserListCollectionViewSocialItem) {

        if let index = collectionView?.indexPath(for: cell), let currentItem = data?.items[(index as NSIndexPath).item].preferredLocalizedItem(UsersMomentCollectionViewController.CurrentLocaleCode) {

            switch item {
            case .facebook:
                if let url = currentItem.facebookUrl {
                    UIApplication.shared.openURL(URL(string: url)!)
                } else {
                    let controller = UIAlertController(title: "Facebook profile unavailable", message: nil, preferredStyle: .alert)
                    self.present(controller, animated: true, completion: nil)
                }
            case .linkedIn:
//                if let url = currentItem. {
//                    UIApplication.sharedApplication.openURL(NSURL(string: url)!)
//                } else {
                    let controller = UIAlertController(title: "LinkedIn profile unavailable", message: nil, preferredStyle: .alert)
                    self.present(controller, animated: true, completion: nil)
                //                }
                
            case .twitter:
                if let url = currentItem.twitterUrl {
                    UIApplication.shared.openURL(URL(string: url)!)
                } else {
                    let controller = UIAlertController(title: "Twitter profile unavailable", message: nil, preferredStyle: .alert)
                    self.present(controller, animated: true, completion: nil)
                }
            case .instagram:
                if let url = currentItem.instagramUrl {
                    UIApplication.shared.openURL(URL(string: url)!)
                } else {
                    let controller = UIAlertController(title: "LinkedIn profile unavailable", message: nil, preferredStyle: .alert)
                    self.present(controller, animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK -- Models
    open class UsersMomentData : NSObject, ResponseObjectSerializable {

        open var id : Int!
        open var displayBioOnMainView: Bool = false
        open var items: [DataItem] = []

        init?(dictionary:NSDictionary) {
            super.init()
            id = (dictionary.value(forKey: "id") as! NSNumber).intValue
            _ = displayBioOnMainView = (dictionary.value(forKey: "id") as? NSNumber ?? NSNumber.init(value: false)).boolValue
            
            if let itemArray = dictionary.value(forKey: "users") as? [NSDictionary] {
                for item in itemArray {
                    if let item = DataItem(dictionary: item) {
                        items.append(item)
                    }
                }
            }
        }
        
        required public init?(response: HTTPURLResponse, representation: AnyObject) {
            super.init()
            if let repn = representation as? NSDictionary , commonInit(repn) == false {
                return nil
            }
        }
        
        fileprivate func commonInit(_ dictionary: NSDictionary) -> Bool {
            if let id = (dictionary.value(forKey: "id") as? NSNumber)?.intValue {
                self.id = id
                displayBioOnMainView = (dictionary.value(forKey: "id") as! NSNumber).boolValue 
                if let itemArray = dictionary.value(forKey: "users") as? [NSDictionary] {
                    for item in itemArray {
                        if let item = DataItem(dictionary: item) {
                            items.append(item)
                        }
                    }
                }
            } else {
                return false
            }
            return true
        }

        open class DataItem {
            open var id : Int!
            open var imageUrl: String?
            open var backgroundImageUrl: String?
            open var localization: [String:ProfileItem] = [:]

            open func preferredLocalizedItem(_ locale:String?) -> ProfileItem? {
                if let locale = locale , localization[locale] != nil {
                    return localization[locale]
                } else if let key = localization.first{
                    return key.1
                }
                return nil
            }

            init?(dictionary:NSDictionary) {
                id = (dictionary.value(forKey: "id") as! NSNumber).intValue
                imageUrl = dictionary.value(forKey: "imageUrl") as? String
                backgroundImageUrl = dictionary.value(forKey: "backgroundImageUrl") as? String

                if let locales = dictionary.value(forKey: "locales") as? [String:AnyObject] {
                    for (key, loc) in locales {
                        if let item = ProfileItem(dictionary: loc as! NSDictionary) {

                            localization[key] = item
                        }
                    }
                }
            }
        }

        //MARK - Item class
        open class ProfileItem {
            open var id : String!
            open var locale : String!
            open var firstName : String?
            open var lastName : String?
            open var position : String?
            open var branchTransitNumber : String?
            open var phoneNumber : String?
            open var email : String?
            open var aboutMe : String?
            open var facebookUrl : String?
            open var twitterUrl : String?
            open var spotifyUrl : String?
            open var iTunesUrl : String?
            open var googleMusicStoreUrl : String? 
            open var instagramUrl : String?

            open var fullname : String {
                return (firstName ?? "") + " " + (lastName ?? "")
            }

            init?(dictionary:NSDictionary) {
                guard let id = dictionary.htmlDecodedString("id"), let locale = dictionary.htmlDecodedString("locale") else { return nil }
                self.id              = id
                self.locale          = locale
                firstName            = dictionary.htmlDecodedString("firstName")
                lastName             = dictionary.htmlDecodedString("lastName")
                position             = dictionary.htmlDecodedString("position")
                branchTransitNumber  = dictionary.htmlDecodedString("branchTransitNumber")
                phoneNumber          = dictionary.htmlDecodedString("phoneNumber")
                email                = dictionary.htmlDecodedString("email")
                aboutMe              = dictionary.htmlDecodedString("aboutMe")
                facebookUrl          = dictionary.htmlDecodedString("facebookUrl")
                twitterUrl           = dictionary.htmlDecodedString("twitterUrl")
                spotifyUrl           = dictionary.htmlDecodedString("spotifyUrl")
                iTunesUrl            = dictionary.htmlDecodedString("iTunesUrl")
                googleMusicStoreUrl  = dictionary.htmlDecodedString("googleMusicStoreUrl")
                instagramUrl         = dictionary.htmlDecodedString("instagramUrl")

            }
        }

    }
}

private extension NSDictionary {
    func urlStringForKey(_ key:String) -> String? {
        guard let url = self.value(forKey: key) as? String else { return nil }
        
        let loadableUrl:String
        // if its missing uri scheme, add http as the default otherwise webview doesn't load
        if url.range(of: "(.*)://", options: NSString.CompareOptions.regularExpression, range: nil, locale: nil) == nil {
            loadableUrl = "http://" + url
        } else {
            loadableUrl = url
        }
        return loadableUrl
    }
}


enum UserMomentRequest : Requestable {
    
    // --- cases
    case getUsers(moment: Moment, allLocales: Bool, completion: (_ data: UsersMomentCollectionViewController.UsersMomentData?, _ error: NSError?) -> Void)
    
    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }
    
    var baseURI: String {
        switch self {
        case let .getUsers(moment, allLocales, _):
            return moment.launchURL + "/UsersBits" + (allLocales ? "?alllocales=true" : "")
        }
    }
    
    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getUsers(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: UsersMomentCollectionViewController.UsersMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}
