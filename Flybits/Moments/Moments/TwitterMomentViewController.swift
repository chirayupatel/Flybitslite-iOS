//
//  TwitterMomentViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-19.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


open class TwitterMomentViewController: UIViewController, MomentModule, UITableViewDelegate, UITableViewDataSource {

    open var moment:Moment!
    open var requestTask : URLSessionDataTask?
    var validateRequest: FlybitsRequest?

    fileprivate var data: TwitterMomentData?
    fileprivate var loadingView: LoadingView?
    fileprivate var tableView: UITableView!
    fileprivate var fetching: Bool = false {
        didSet {
            self.tableView?.reloadData()
        }
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

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    open override func loadView() {
        super.loadView()
        tableView = UITableView(frame: self.view.frame, style: UITableViewStyle.grouped)
        self.view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.equal(.top, view1: tableView, asView: view)
        NSLayoutConstraint.equal(.leading, view1: tableView, asView: view)
        NSLayoutConstraint.equal(.width, view1: tableView, asView: view)
        NSLayoutConstraint.equal(.height, view1: tableView, asView: view)
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.title = moment?.name.value
        guard let moment = moment else { return }

        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.white
        loadingView = dimmedLoadingView

        fetching = true
        validateRequest = moment.validate({ (success, error) in
            OperationQueue.main.addOperation {
                if success {
                    self.loadData(dimmedLoadingView)
                } else {
                    self.fetching = false
                    let alert = UIAlertController.cancellableAlertConroller("Unable to validate the moment", message: error?.localizedDescription, handler: nil)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let loading = self.loadingView {
            self.view.bringSubview(toFront: loading)
            loading.frame = self.view.bounds
        }
    }

    func loadData(_ loadingView:UIView?) {
        self.title = moment.name.value

        _ = TwitterMomentRequest.getHandles(moment: self.moment, allLocales: true) { (data, error) -> Void in
            self.didDownloadData(data, loadingView: loadingView)
        }.execute()
    }

    open func didDownloadData(_ data: TwitterMomentData?, loadingView: UIView?) {
        OperationQueue.main.addOperation {
            self.data = data
            self.tableView.reloadData()
            if let data = data, let first = data.items.first , data.items.count == 1 {
                self.openItem(first)
            }
            loadingView?.removeFromSuperview()
            self.fetching = false
        }
    }

    //MARK: UITableView stufff

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetching {
            return 0
        }
        if let count = data?.items.count , count > 0 {
            return count
        }
        return 1
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard data?.items.count > 0 else {
            let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "EmptyCell")
            cell.textLabel?.text = "There are no Twitter handles available."
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textAlignment = NSTextAlignment.center
            return cell
        }

        let item = data!.items[(indexPath as NSIndexPath).row]
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "listCell")
        cell.contentView.backgroundColor = UIColor.darkGray
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = item.handle
        return cell
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        // ignore tap on empty cell
        guard data?.items.count > 0 else {
            return
        }

        let item = data!.items[(indexPath as NSIndexPath).row]
        openItem(item)
    }

    fileprivate func openItem(_ item: TwitterMomentData.TwitterData) {
        let vc = WebViewController()
        vc.twitterHandle = item.handle
        vc.title = item.handle
        self.navigationController?.pushViewController(vc, animated: true)
    }

    open func initialize(_ moment:Moment) {
        self.moment = moment
    }

    open func load(_ moment:Moment, info:AnyObject?) {
        load(moment, info: info, completion: nil)
    }

    open func load(_ moment:Moment, info:AnyObject?, completion:((_ data:Data?, _ error:NSError?, _ otherInfo:NSDictionary?)->Void)?) {
        self.moment = moment
    }

    open func unload(_ moment:Moment) {
        _ = validateRequest?.cancel()
        requestTask?.cancel()
    }

    // MARK: - Moment Data
    open class TwitterMomentData : ResponseObjectSerializable  {

        open class TwitterData : NSObject, ResponseObjectSerializable {
            open var id: Int!
            open var handle: String?
            open var zoneMomentInstanceId: String?
            open var locale: String?

            init?(dictionary: NSDictionary) {
                super.init()
                if commonInit(dictionary) == false {
                    return nil
                }
            }

            public required init?(response: HTTPURLResponse, representation: AnyObject) {
                super.init()
                if let dictionary = representation as? NSDictionary {
                    if commonInit(dictionary) == false {
                        return nil
                    }
                }
            }

            fileprivate func commonInit(_ dictionary: NSDictionary) -> Bool {
                guard let handleId = dictionary.numForKey("id")?.intValue else {
                    return false
                }
                guard let twitterHandle = dictionary.htmlDecodedString("handle") else {
                    return false
                }

                id = handleId
                handle = twitterHandle
                zoneMomentInstanceId = dictionary.htmlDecodedString("zoneMomentInstanceId")
                locale = dictionary.htmlDecodedString("locale")
                return true
            }
        }

        open var items:[TwitterData] = []
        public required init?(response: HTTPURLResponse, representation: AnyObject) {
            if let array = representation as? [NSDictionary] {
                for item in array {
                    if let data = TwitterData(dictionary: item) {
                        items.append(data)
                    }
                }
            }
        }

        init?(array: NSArray) {
            if let array = array as? [NSDictionary] {
                for item in array {
                    if let data = TwitterData(dictionary: item) {
                        items.append(data)
                    }
                }
            }
        }
    }
}



private class WebViewController: UIViewController {
    fileprivate lazy var localizationButton:UIBarButtonItem = UIBarButtonItem(title: "Lang", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.changeLocalization(_:)))

    var webView:UIWebView!

    var twitterItem: TwitterMomentViewController.TwitterMomentData! {
        didSet {
            setupLocalizationButtons()

        }
    }

    fileprivate var twitterHandle: String! {
        didSet {
            if let twitterHandle = twitterHandle {
                self.loadTwitterHandle(twitterHandle)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = UIWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)

        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[web]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["web":webView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[web]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["web":webView]))
        self.loadTwitterHandle(self.twitterHandle)
    }

    func loadTwitterHandle(_ handle:String) {
        guard let webView = webView else {
            return
        }
        let request = URLRequest(url: URL(string: "https://twitter.com/\(handle)")!)
        webView.loadRequest(request)
    }

    @objc func changeLocalization(_ sender: UIBarButtonItem) {

        let data = twitterItem

        let controller = UIAlertController(title: "Localized page in", message: nil, preferredStyle: UIAlertControllerStyle.alert)

        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            controller.dismiss(animated: true, completion: nil)
        }))

        for x in (data?.items)! where x.handle != nil {
            controller.addAction(UIAlertAction(title: x.handle!.uppercased(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.loadTwitterHandle(x.handle!)
                self.localizationButton.title = action.title
            }))
        }

        present(controller, animated: true, completion: nil)
    }

    func setupLocalizationButtons() {

        let data = twitterItem
        let deviceLocale:String
        if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            deviceLocale = deviceLocaleIdentifier.uppercased()
        } else {
            deviceLocale = "en".uppercased()
        }

        var didSet = false
        for item in (data?.items)! where item.locale?.uppercased() == deviceLocale {
            didSet = true
            self.twitterHandle = item.handle!
            self.localizationButton.title = item.handle!
        }

        if let first = data?.items.first, let handle = first.handle , !didSet {
            self.twitterHandle = handle
            self.localizationButton.title = first.handle
        }

        if data?.items.count > 1 {
            navigationItem.rightBarButtonItem = localizationButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

}

/**
 Example:

 TwitterMomentRequest.GetHandle(moment: self.moment, handleID: 22) { (data, error) -> Void in
    print(data?.handle)
 }.execute()

*/
enum TwitterMomentRequest : Requestable {

    // --- cases
    case getHandles(moment: Moment, allLocales: Bool, completion: (_ data: TwitterMomentViewController.TwitterMomentData?, _ error: NSError?) -> Void)
    case getHandle(moment: Moment, handleID: Int, completion: (_ data: TwitterMomentViewController.TwitterMomentData.TwitterData?, _ error: NSError?) -> Void)

    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }

    var baseURI: String {
        switch self {
        case let .getHandles(moment, allLocales, _):
            return moment.launchURL + "/SearchFilters" + (allLocales ? "?alllocales=true" : "")
        case let .getHandle(moment, handleId, _):
            return moment.launchURL + "/SearchFilters/\(handleId)"
        }
    }

    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getHandles(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: TwitterMomentViewController.TwitterMomentData?, error) -> Void in
                completion(data, error)
            }
        case .getHandle(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: TwitterMomentViewController.TwitterMomentData.TwitterData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}
