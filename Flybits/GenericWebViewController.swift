//
//  GenericWebViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-20.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class GenericWebViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!

    var request: URLRequest? {
        didSet {
            updateUI()
        }
    }

    var URLString: String? {
        didSet {
            updateUI()
        }
    }
    
    var HTMLString: String? {
        didSet {
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    func updateUI() {
        guard let webView = webView else {
            print("No URL/Request provided for WebView")
            return
        }

        if let HTMLString  = HTMLString {
            webView.loadHTMLString(HTMLString, baseURL: nil)
        } else if let request = request {
            webView.loadRequest(request)
        } else if let urlStr = URLString, let url = URL(string: urlStr) {
            let req = URLRequest(url: url)
            webView.loadRequest(req)
        } else {
            print("No URL/Request provided for WebView")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
