//
//  LiteOAuthConsentViewController.swift
//  Flybits
//
//  Created by Archuthan Vijayaratnam on 2016-04-12.
//  Copyright © 2016 Flybits. All rights reserved.
//

import Foundation
import FlybitsSDK

final public class LiteOAuthConsentViewController: OAuthConsentViewController, OAuthConsentViewControllerDelegate {
    
    enum Status : ContextPluginPermissionType {
        case none // not displayed
        case displayed // displayed to user but user didn't make any
        case failed(error: NSError?) // user explicitly denied or failed
        case accepted // user accepted
        
        var stringVal: String {
            switch self {
            case .none: return "-"
            case .displayed: return "--"
            case .accepted: return "Success"
            case .failed: return "Denied/Error"
            }
        }
    }
    
    var status: Status = .none
    var statusChanged: ((_ controller: LiteOAuthConsentViewController, _ status: Status) -> Void)?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    init(provider: OAuthProvider) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        self.provider = provider
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.delegate = self
    }
    
    override public func didMove(toParentViewController parent: UIViewController?) {
        if parent != nil {
            precondition(self.provider != nil, #file, file: "is displayed without setting a OAuthProvider")
            status = .displayed
            statusChanged?(self, status)
            self.performOAuthRequest()
        }
    }
    
    public func controllerDidFinishSuccessfully(_ controller: FlybitsSDK.OAuthConsentViewController) {
        status = .accepted
        statusChanged?(self, status)
    }
    
    public func controller(_ controller: FlybitsSDK.OAuthConsentViewController, didFailWithError error: NSError) {
        print(error)
        status = .failed(error: error)
        statusChanged?(self, status)
    }
}

