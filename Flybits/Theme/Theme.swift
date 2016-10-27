//
//  Theme.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

enum ThemeType {
    case primary
    case secondary
}


protocol Theming : class {

    var buttonCornerRadius: CGFloat { get }
    func buttonTextColor(_ state:UIControlState) -> UIColor
    func buttonBackgroundColor(_ state:UIControlState) -> UIColor
    func themeNavigationBar(_ navBar:UINavigationBar)

    var navigationBarBackgroundColor: UIColor { get }

    var labelTextColor: UIColor { get }

    var layerHamburgerMenuBackground: CALayer { get }

    var imageDefaultAvatar: UIImage { get }
    
    var viewBackgroundColor: UIColor { get }
    var hamburgerMenu: UIImage! { get }
    
    var zoneViewSearchBarButtonImage: UIImage! { get }
    var zoneViewFilterBarButtonImage: UIImage! { get }
    var zoneViewFilterArrowImage: UIImage! { get }
    var zoneViewFilterBackgroundColor: UIColor! { get }

}


private let _primaryTheme:Theming = FlybitsTheme(type:.primary)
private let _secondaryTheme:Theming = FlybitsTheme(type:.secondary)

class Theme {
    class var primary: Theming {
        return _primaryTheme
    }
    class var secondary: Theming {
        return _secondaryTheme
    }
    class var currentTheme: Theming {
        return _primaryTheme
    }
}

class FlybitsTheme: Theming {
    var type: ThemeType

    init(type:ThemeType) {
        self.type = type
    }

    var buttonCornerRadius: CGFloat {
        return 4
    }
    func buttonTextColor(_ state:UIControlState) -> UIColor {
        switch type {
        case .primary: return UIColor.white
        case .secondary: return UIColor.primaryButtonColor()
        }
    }

    func buttonBackgroundColor(_ state:UIControlState) -> UIColor {
        switch type {
        case .primary: return UIColor.primaryButtonColor()
        case .secondary: return UIColor.white
        }
    }

    var navigationBarBackgroundColor: UIColor {
        switch type {
        case .primary: return UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        case .secondary: return UIColor.clear
        }
    }

    var labelTextColor: UIColor {
        switch type {
        case .primary: return UIColor.darkGray
        case .secondary: return UIColor.primaryButtonColor()
        }
    }

    var layerHamburgerMenuBackground: CALayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [

            UIColor(red: 0.153, green: 0.404, blue: 0.627, alpha: 1).cgColor,
            UIColor(red: 0.149, green: 0.663, blue: 0.878, alpha: 1).cgColor,
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)

        return gradientLayer
    }
    var hamburgerMenu: UIImage! {
        return UIImage(named: "ic_menu_b")!
    }

    var imageDefaultAvatar: UIImage {
        return UIImage(named: "ic_useravatar")!
    }

    var viewBackgroundColor: UIColor {
        switch type {
        case .primary: return UIColor.lightGray
        case .secondary: return UIColor.primaryButtonColor()
        }
    }


    func themeNavigationBar(_ navBar:UINavigationBar) {
        let appearance = navBar
        appearance.setBackgroundImage(nil, for: UIBarMetrics.default)
        appearance.isTranslucent = false
        appearance.backgroundColor = UIColor.white
        appearance.backIndicatorImage = nil
        appearance.backIndicatorTransitionMaskImage = nil
        appearance.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.primaryButtonColor()]
    }
    
    //MARK: Zone View
    
    var zoneViewSearchBarButtonImage: UIImage! {
        return UIImage(named: "ic_search_b")
    }
    var zoneViewFilterBarButtonImage: UIImage! {
        return UIImage(named: "ic_filter_b")
    }
    var zoneViewFilterArrowImage: UIImage! {
        return UIImage(named: "triangle_b")
    }
    var zoneViewFilterBackgroundColor: UIColor! {
        return UIColor.white
    }

}

extension UINavigationBar {
    func Flybits_updateNavbarTheme() {
        Theme.primary.themeNavigationBar(self)
    }
}

extension UIColor {
    class func primaryButtonColor() -> UIColor {
        return UIColor(red: 0.161, green: 0.671, blue: 0.886, alpha: 1.0)
    }
}
