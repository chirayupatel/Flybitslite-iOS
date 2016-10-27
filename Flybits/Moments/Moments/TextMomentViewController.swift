//
//  TextMomentViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-17.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
import WebKit

open class TextMomentViewController: UIViewController, MomentModule {

    open var moment:Moment!
    open var requestTask : FlybitsRequest?
    var validateRequest: FlybitsRequest?

    fileprivate var data: TextMomentData?
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

        validateRequest = moment.validate({ (success, error) in
            if success {
                self.loadData(dimmedLoadingView)
            } else {
                if let msg = error?.userInfo[NSLocalizedDescriptionKey] as? Data {
                    self.loadWebViewWithContent("<p>\(NSString(data: msg, encoding: String.Encoding.utf8.rawValue))</p>")
                    return
                }
                if let msg = error?.userInfo[NSLocalizedDescriptionKey] as? NSString,
                    let data = msg.data(using: String.Encoding.utf8.rawValue),
                    let displayableMessage = String(data: data, encoding: String.Encoding.utf8) {
                        self.loadWebViewWithContent("<p>\(displayableMessage)</p>")
                        return
                } else if let msg = error?.localizedDescription {
                    self.loadWebViewWithContent("<p>\(msg)</p>")
                    return
                }
                self.loadWebViewWithContent("<p>An error has occured.</p>")
                print(error)
            }
        })
    }

    func loadData(_ loadingView:UIView?) {
        self.title = moment.name.value
        requestTask = TextMomentRequest.getTexts(moment: self.moment, allLocales: true) { (data, error) -> Void in
            defer {
                OperationQueue.main.addOperation {
                    loadingView?.removeFromSuperview()
                }
            }
            OperationQueue.main.addOperation({
                self.data = data
                self.didDownloadData()
            })
        }.execute()
    }

    open func didDownloadData() {

        guard let data = data else {
            self.displayErrorView()
            return
        }

        let deviceLocale:String
        if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            deviceLocale = deviceLocaleIdentifier.uppercased()
        } else {
            deviceLocale = "en".uppercased()
        }

        var didSet = false
        for (locale, item) in data.texts where locale.uppercased() == deviceLocale {
            didSet = true
            self.loadWebViewWithContent(item.summary)
            self.localizationButton.title = locale.uppercased()
        }

        if !didSet {
            if let (locale, item) = data.texts.first, let content = item.summary  {
                self.loadWebViewWithContent(content)
                self.localizationButton.title = locale.uppercased()
            } else {
                self.displayErrorView()
            }
        }

        if data.texts.count > 1 {
            navigationItem.rightBarButtonItem = localizationButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    open func changeLocalization(_ sender: UIBarButtonItem) {
        guard let data = data else { return }

        let controller = UIAlertController(title: "Localized page in", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        controller.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            controller.dismiss(animated: true, completion: nil)
        }))

        for (locale, item) in data.texts {
            controller.addAction(UIAlertAction(title: locale.uppercased(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.loadWebViewWithContent(item.summary)
                self.localizationButton.title = action.title
            }))
        }
        present(controller, animated: true, completion: nil)
    }

    fileprivate func displayErrorView() {
        self.loadWebViewWithContent("<p>There are no text available.<p>")
    }

    open func loadWebViewWithContent(_ content:String?) {
        guard let content = content?.Lite_HTMLDecodedString.replacingOccurrences(of: "\n", with: "<br />") else {
            self.displayErrorView()
            return
        }

        guard content.characters.count > 0 else {
            self.displayErrorView()
            return
        }

        let font = UIFont.systemFont(ofSize: 15)
        let fontSize = "\(font.pointSize)px"

        let style = "<style> body {background-color:#45576E; color:#CACBCD; font-family: \"Helvetica Neue\"; font-size: \(fontSize) text-align: center; }; </style>"
        let meta = "<meta name=\"viewport\" content=\"width=device-width; minimum-scale=1.0; maximum-scale=1.0;\">"
        let newContent = "<html><head>\(meta)\(style)</head><body>\(content)</body></html>"
        webView.loadHTMLString(newContent, baseURL: nil)
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
        _ = requestTask?.cancel()
    }

    // MARK: - Moment Data
    open class TextMomentData : AbstractMomentData {

        open class TextData : NSObject {
            open var id: Int = -1
            open var title: String?
            open var summary: String?

            init?(dictionary: NSDictionary) {
                id      = dictionary.numForKey("id")?.intValue ?? -1
                summary = dictionary.htmlDecodedString("description")
                title   = dictionary.htmlDecodedString("title")
            }
        }

        open var texts:[String:TextData] = [:]

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
            guard let textsData = dictionary.value(forKey: "texts") as? [[String:AnyObject]] else {
                return
            }
            for itemDict in textsData {
                guard let id = (itemDict["id"] as? NSNumber)?.intValue, let locales = itemDict["locales"] as? [String:AnyObject] else {
                    continue
                }

                for (lang, data) in locales {
                    if let item = TextData(dictionary: data as! NSDictionary) {
                        item.id = id
                        texts[lang] = item
                    }
                }
            }
        }
    }
}

enum TextMomentRequest : Requestable {

    // --- cases
    case getTexts(moment: Moment, allLocales: Bool, completion:(_ data: TextMomentViewController.TextMomentData?, _ error: NSError?) -> Void)
    case getText(moment: Moment, textID: Int, completion:(_ data: TextMomentViewController.TextMomentData?, _ error: NSError?) -> Void)

    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }

    var baseURI: String {
        switch self {
        case let .getTexts(moment, allLocales, _):
            return moment.launchURL + "/TextBits" + (allLocales ? "?alllocales=true" : "")
        case let .getText(moment, textID, _):
            return moment.launchURL + "/TextBits/\(textID)"
        }
    }

    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getTexts(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: TextMomentViewController.TextMomentData?, error) -> Void in
                completion(data, error)
            }
        case .getText(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: TextMomentViewController.TextMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}

