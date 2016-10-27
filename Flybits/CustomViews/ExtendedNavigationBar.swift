//
//  ExtendedNavigationBar.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-11.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

private struct Constants {
    struct Animation {
        static let Duration: TimeInterval = 0.0
    }
    struct Banner {
        static let ViewHeightHidden:CGFloat = 0
        static let ViewHeightVisible:CGFloat = 44
        static let TextColor  = UIColor.white
        static let BackgroundColor = UIColor.black
    }
}

open class MessageBanner : NSObject {
    var height: CGFloat          = Constants.Banner.ViewHeightVisible
    var text:String              = ""
    var textColor: UIColor       = Constants.Banner.TextColor
    var backgroundColor: UIColor = Constants.Banner.BackgroundColor

    class func errorMessage(_ text:String) -> MessageBanner {
        let banner              = MessageBanner()
        banner.text             = text
        banner.backgroundColor  = UIColor.red
        banner.textColor        = UIColor.white
        return banner
    }
    
    class func successMessage(_ text:String) -> MessageBanner {
        let banner              = MessageBanner()
        banner.text             = text
        banner.backgroundColor  = UIColor.green
        banner.textColor        = UIColor.white
        return banner
    }

}

class ExtendedNavigationBar: UINavigationBar {

    var banner: MessageBanner? {
        didSet {
            if banner != nil {
                extendedView.text = banner?.text
            }
        }
    }
    
    fileprivate var extendedView: UILabel = UILabel()

    @IBInspectable var clearNavigationBar: Bool = false {
        didSet {
            if clearNavigationBar {
                setBackgroundImage(UIImage(named: "TransparentPixel"), for: UIBarMetrics.default)
                shadowImage = UIImage(named: "TransparentPixel")
                backgroundColor = UIColor.clear
                tintColor = UIColor.white
                isTranslucent = true
                barTintColor = UIColor.clear
//                titleTextAttributes = [NSForegroundColorAttributeName:UIColor.clearColor()]
            } else {

                isTranslucent = false
                tintColor = UIColor.primaryButtonColor()
                barTintColor = UIColor.white
                shadowImage = UIImage(named: "TransparentPixel")
                titleTextAttributes = [NSForegroundColorAttributeName:UIColor.primaryButtonColor()]

            }
        }
    }

    func displayBanner(_ banner:MessageBanner, duration: TimeInterval = Constants.Animation.Duration) {
        self.banner = banner
        self.extendedView.isHidden = false
        self.extendedView.frame = CGRect(x: 0, y: self.bounds.size.height, width: self.bounds.size.width, height: Constants.Banner.ViewHeightHidden)
        self.extendedView.backgroundColor = banner.backgroundColor
        self.extendedView.textColor = banner.textColor
        self.extendedView.text = banner.text
        self.extendedView.font = UIFont.systemFont(ofSize: 14.0)

        UIView.animate(withDuration: duration, animations: {
            self.extendedView.frame = CGRect(x: 0, y: self.bounds.size.height, width: self.bounds.size.width, height: Constants.Banner.ViewHeightVisible)

        }, completion: { (finished) -> Void in

        }) 
    }

    func removeBanner(_ duration: TimeInterval = Constants.Animation.Duration) {

        self.extendedView.frame = CGRect(x: 0, y: self.bounds.size.height, width: self.bounds.size.width, height: Constants.Banner.ViewHeightVisible)
        UIView.animate(withDuration: duration, animations: {
            self.extendedView.frame = CGRect(x: 0, y: self.bounds.size.height, width: self.bounds.size.width, height: Constants.Banner.ViewHeightHidden)
        }, completion: { (finished) -> Void in
            self.banner = nil
            self.extendedView.isHidden = true
        })
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(extendedView)
        extendedView.isHidden = true
        extendedView.frame = CGRect(x: 0, y: self.bounds.size.height, width: self.bounds.size.width, height: Constants.Banner.ViewHeightHidden)
        extendedView.textAlignment = NSTextAlignment.center

        self.backgroundColor = UIColor.white.withAlphaComponent(0.6)
    }
}
