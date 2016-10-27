//
//  MomentHandler.swift
//  Flybits
//
//  Created by chu on 2015-09-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

open class WebPageMomentViewController: UIViewController, MomentModule {

    open var moment:Moment!

    fileprivate var data: WebMomentData?
    fileprivate lazy var localizationButton:UIBarButtonItem = UIBarButtonItem(title: "Lang", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebPageMomentViewController.changeLocalization(_:)))

    @IBOutlet var webView:UIWebView!

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

    deinit {
        print("DEINIT \(self)")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_back_b")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal), style: UIBarButtonItemStyle.plain, target: nil, action: nil)

        webView = UIWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)

        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[web]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["web":webView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[web]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["web":webView]))
        self.title = moment?.name.value

        guard let moment = moment else { return }

        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        _ = moment.validate({ [weak self](success, error) in
            if success {
                self?.loadData(dimmedLoadingView)
            } else {
                OperationQueue.main.addOperation { [weak self] in
                    if let error = error, let flybitsError = Utils.ErrorChecker.FlybitsError(error) {
                        let alert = UIAlertController.cancellableAlertConroller("Validation Failed", message: flybitsError.exceptionMessage, handler: nil)
                        self?.present(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController.cancellableAlertConroller("Validation Failed", message: error?.localizedDescription, handler: nil)
                        self?.present(alert, animated: true, completion: nil)
                    }
                    dimmedLoadingView.removeFromSuperview()
                }
            }
        })
    }

    func loadData(_ loadingView:UIView?) {
        self.title = moment.name.value
        _ = WebMomentRequest.getWebsites(moment: self.moment, allLocales: true) { [weak self](data, error) -> Void in
            defer {
                OperationQueue.main.addOperation {
                    loadingView?.removeFromSuperview()
                }
            }
            self?.data = data
            self?.didDownloadData()
        }.execute()
    }

    open func didDownloadData() {

        guard let data = data else {
            displayEmptyView(self.webView)
            return
        }

        let deviceLocale:String
        if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            deviceLocale = deviceLocaleIdentifier.uppercased()
        } else {
            deviceLocale = "en".uppercased()
        }

        var didSet = false
        for x in data.websites where x.locale.uppercased() == deviceLocale {
            didSet = true

            self.loadWebView(x.URLString!)
            self.localizationButton.title = x.locale.uppercased()
        }

        if !didSet {
            if let first = data.websites.first, let url = first.URLString  {
                self.loadWebView(url)
                self.localizationButton.title = first.locale.uppercased()
            } else {
                displayEmptyView(self.webView)
            }
        }

        if data.websites.count > 1 {
            navigationItem.rightBarButtonItem = localizationButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }

    }

    open func changeLocalization(_ sender: UIBarButtonItem) {
        let controller = UIAlertController(title: "Localized page in", message: nil, preferredStyle: UIAlertControllerStyle.alert)

        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            controller.dismiss(animated: true, completion: nil)
        }))

        for item in data!.websites {
            controller.addAction(UIAlertAction(title: item.locale.uppercased(), style: UIAlertActionStyle.default, handler: { [weak self](action) -> Void in
                print(item.URLString)
                if let urlString = item.URLString {
                    self?.loadWebView(urlString)
                    self?.localizationButton.title = action.title
                } else {
                    if let tempSelf = self {
                        tempSelf.displayEmptyView(tempSelf.webView)
                    }
                }
            }))
        }
        present(controller, animated: true, completion: nil)
    }

    open func loadWebView(_ url:String) {

        let loadableUrl:String
        // if its missing uri scheme, add http as the default otherwise webview doesn't load
        if url.range(of: "(.*)://", options: NSString.CompareOptions.regularExpression, range: nil, locale: nil) == nil {
            loadableUrl = "http://" + url
        } else {
            loadableUrl = url
        }

        let request = URLRequest(url: URL(string: loadableUrl)!)
        webView.loadRequest(request)
    }


    func displayEmptyView(_ webView:UIWebView?) {
        guard let webView = webView else { return }
        let str = "<p>No URL available to load webpage<p>"
        webView.loadHTMLString(str, baseURL: nil)
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
    }

    // MARK: - Moment Data
    open class WebMomentData : AbstractMomentData {

        open class WebData : NSObject {
            open var title: String?
            open var summary: String?
            open var URLString: String?
            open var locale: String!

            open var URL: Foundation.URL? {
                get {
                    if let URLString = URLString {
                        return Foundation.URL(string: URLString)
                    }
                    return nil
                }
            }

            init?(dictionary: NSDictionary) {
                summary = dictionary.htmlDecodedString("description")?.Lite_HTMLDecodedString
                title = dictionary.htmlDecodedString("title")?.Lite_HTMLDecodedString
                URLString = dictionary.value(forKey: "url") as? String
            }
       }

        open var websites:[WebData] = []

        override init?(dictionary: NSDictionary) {
            super.init(dictionary: dictionary)
            readFromDictionary(dictionary)
        }

        public required init?(response: HTTPURLResponse, representation: AnyObject) {
            super.init(response: response, representation: representation)
            guard let rep = representation as? NSDictionary else {
                return nil
            }
            readFromDictionary(rep)
        }

        fileprivate func readFromDictionary(_ dictionary: NSDictionary) {
            for (locale, itemDict) in dictionary as! [String:AnyObject] {
                let webs = itemDict["websites"] as? [[String:AnyObject]]
                if let webs = webs {
                    for data in webs {
                        if let item = WebData(dictionary: data as NSDictionary) {
                            item.locale = locale
                            websites.append(item)
                        }
                    }
                }
            }
        }
    }
}

enum WebMomentRequest : Requestable {

    // --- cases
    case getWebsites(moment: Moment, allLocales: Bool, completion:(_ data: WebPageMomentViewController.WebMomentData?, _ error: NSError?) -> Void)
    case getWebsite(moment: Moment, websiteID: Int, completion:(_ data: WebPageMomentViewController.WebMomentData?, _ error: NSError?) -> Void)

    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }

    var baseURI: String {
        switch self {
        case let .getWebsites(moment, allLocales, _):
            return moment.launchURL + "/WebsiteBits" + (allLocales ? "?alllocales=true" : "")
        case let .getWebsite(moment, websiteID, _):
            return moment.launchURL + "/WebsiteBits/\(websiteID)"
        }
    }

    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getWebsites(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: WebPageMomentViewController.WebMomentData?, error) -> Void in
                completion(data, error)
            }
        case .getWebsite(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: WebPageMomentViewController.WebMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}
