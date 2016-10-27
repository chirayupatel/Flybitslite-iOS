//
//  HTMLMomentViewController.swift
//  Flybits
//
//  Created by Archu on 2016-01-15.
//  Copyright © 2016 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

open class HTMLMomentViewController: UIViewController, MomentModule {
    open var moment: Moment!
    fileprivate var webView: UIWebView!

    open override func loadView() {
        super.loadView()
        webView = UIWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        
        NSLayoutConstraint.equal(.top, view1: webView, asView: view)
        NSLayoutConstraint.equal(.leading, view1: webView, asView: view)
        NSLayoutConstraint.equal(.width, view1: webView, asView: view)
        NSLayoutConstraint.equal(.height, view1: webView, asView: view)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.loadWebsite()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func showEmptyView() {
        let content = "<p>Unable to load the moment at this time.</p>"
        
        let font = UIFont.systemFont(ofSize: 15)
        let fontSize = "\(font.pointSize)px"
        
        let style = "<style> body {background-color:#45576E; color:#CACBCD; font-family: \"Helvetica Neue\"; font-size: \(fontSize) text-align: center; }; </style>"
        let meta = "<meta name=\"viewport\" content=\"width=device-width; minimum-scale=1.0; maximum-scale=1.0;\">"
        let newContent = "<html><head>\(meta)\(style)</head><body>\(content)</body></html>"
        webView.loadHTMLString(newContent, baseURL: nil)
    }
    
    fileprivate func loadWebsite() {
        
        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.white

        _ = MomentRequest.authorize(momentIdentifier: moment.identifier) { (authorization, error) -> Void in
            OperationQueue.main.addOperation({
                if let payload = authorization?.payload, let URL = NSURL(string: self.moment.launchURL + "?payload=\(payload)") {
                    let urlReq = NSURLRequest(url: URL as URL)
                    self.webView.loadRequest(urlReq as URLRequest)
                } else {
                    self.showEmptyView()
                }
                dimmedLoadingView.removeFromSuperview()
            })
        }.execute()
    }

    // MARK: - MomentModule
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
}
