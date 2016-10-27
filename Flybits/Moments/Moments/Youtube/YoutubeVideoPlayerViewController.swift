//
//  YoutubeVideoPlayerViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-19.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import WebKit

class YoutubeVideoPlayerViewController: UIViewController {

    weak var webView: WKWebView?
    var videoID: String? {
        didSet {
            updateView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = WKWebView(frame: self.view.frame, configuration: WKWebViewConfiguration())

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        self.view.addSubview(webView)
        self.webView = webView
        updateView()
    }

    func updateView() {
        if let webView = webView {
            if let videoID = videoID {
                loadVideo(videoID, webView: webView)
            } else {
                displayEmptyView(webView)
            }
        }
    }

    func loadVideo(_ id:String, webView:WKWebView) {
        let url = URL(string: "http://www.youtube.com/embed/\(id)")
        let request = URLRequest(url: url!)
        webView.load(request)
    }

    func displayEmptyView(_ webView:WKWebView) {
        let str = "<p>No video available<p>"
        webView.loadHTMLString(str, baseURL: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.webView?.frame = self.view.bounds
    }
}
