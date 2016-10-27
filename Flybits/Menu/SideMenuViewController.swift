//
//  SideMenuViewController.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-13.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

enum SideMenuIdentifier: String {
    case profile   = "profile"
    case discovery = "discovery"
    case myZones   = "myzones"
    case favourites = "favourites"
    case explore    = "explore"
    case logout     = "logout"
    
    var info: (title: String, image: UIImage?)  {
        switch self {
        case .profile:      return ("SIDEMENU_TITLE_PROFILE".appLocalizedString,         nil)
        case .discovery:    return ("SIDEMENU_TITLE_ZONE_DISCOVERY".appLocalizedString,  UIImage(named: "ic_discovery_w"))
        case .myZones:      return ("SIDEMENU_TITLE_MY_ZONES".appLocalizedString,        UIImage(named: "ic_myzones_w"))
        case .favourites:   return ("SIDEMENU_TITLE_FAVOURITES".appLocalizedString,      UIImage(named: "ic_favorite_star_w"))
        case .explore:      return ("SIDEMENU_TITLE_EXPLORE".appLocalizedString,         UIImage(named: "ic_myzones_w"))
        case .logout:       return ("SIDEMENU_TITLE_LOGOUT".appLocalizedString,          UIImage(named: "ic_logout_w"))
        }
    }
}

protocol SideMenuViewControllerDelegate : class {
    func menuViewController(_ controller: SideMenuViewController, didLoadProfile:User)
    func menuViewController(_ controller: SideMenuViewController, didTapOnProfileView:UIView, profile:User?)
    func menuViewController(_ controller:SideMenuViewController, didSelectItem:SideMenuItemView, identifier:SideMenuIdentifier)
}

protocol MenuViewableDelegate {
    func menuViewableDidTap(_ viewable: MenuViewable)
}

protocol MenuViewable {
    var heightConstraints: [NSLayoutConstraint] { get }
    var menuView: UIView { get }
    var delegate: MenuViewableDelegate? { get set }
    func highlight()
    func unhighlight()
}

extension MenuViewable {
    var heightConstraints: [NSLayoutConstraint] { return [] }
    func highlight() { }
    func unhighlight() { }
}

class ProfileHeaderView: UIView, MenuViewable {
    var delegate: MenuViewableDelegate?
    var menuView: UIView { return self }
    var user: User? {
        didSet {
        updateView()
        }
    }
    var userBtn: UserAvatar = UserAvatar()
    var nameLabel: UILabel = UILabel()
    var heightConstraints: [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AppConstants.UI.UserProfileHeight)
        ]
    }
    
    init(delegate: MenuViewableDelegate? = nil) {
        super.init(frame: CGRect.zero)
        self.delegate = delegate
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userBtnTapped))
        userBtn.addGestureRecognizer(tap)
        userBtn.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userBtn)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.white
        addSubview(nameLabel)

        let views: [String: AnyObject] = ["btn": userBtn, "name": nameLabel]
        let metrics = ["width": AppConstants.UI.UserProfileBtnSize.width as AnyObject, "height": AppConstants.UI.UserProfileBtnSize.height as AnyObject]
        addConstraint("H:[btn(==width)]", metrics: metrics, views: views)
        addConstraint("H:|-[name]-|", metrics: metrics, views: views)
        addConstraint("V:|-[btn(==height)]-[name]-|", metrics: metrics, views: views)
        addConstraint(NSLayoutConstraint(item: userBtn, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: nameLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
    }
    
    func userBtnTapped(_ gesture: UITapGestureRecognizer) {
        delegate?.menuViewableDidTap(self)
    }
    
    fileprivate func updateView() {
        if let firstname = user?.profile?.firstname, let lastname = user?.profile?.lastname {
            nameLabel.text = "\(firstname) \(lastname)"
        } else {
            nameLabel.text = ""
        }
        if let img = user?.profile?.image?.loadedImage() {
            userBtn.image = img
        } else {
            userBtn.image = nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SideMenuItemView: UIView, MenuViewable {
    var delegate: MenuViewableDelegate?
    var id: SideMenuIdentifier
    let image: UIImageView = UIImageView()
    let nameLabel: UILabel = UILabel()
    
    convenience init(id: SideMenuIdentifier, delegate: MenuViewableDelegate? = nil, setup:(SideMenuItemView)->Void) {
        self.init(id:id, delegate: delegate)
        setup(self)
    }

    init(id: SideMenuIdentifier, delegate: MenuViewableDelegate? = nil) {
        self.id = id
        super.init(frame: CGRect.zero)
        self.delegate = delegate
        
        let info = id.info
        
        addSubview(image)
        addSubview(nameLabel)
        
        image.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = UIColor.white
        
        let views: [String : AnyObject] = ["image": image, "nameLabel": nameLabel]
        let metrics = [
            "leadingImg": AppConstants.UI.MenuIconLeading as AnyObject,
            "leadingTitle": AppConstants.UI.MenuTitleLeading as AnyObject,
            "imgWidth": AppConstants.UI.MenuIconSize.width as AnyObject,
            "imgHeight": AppConstants.UI.MenuIconSize.height as AnyObject
        ]

        addConstraint("V:[image(==imgHeight)]", metrics: metrics, views: views)
        addConstraint("H:|-leadingImg-[image(==imgWidth)]-leadingTitle-[nameLabel]-|", metrics: metrics, views: views)
        addConstraint("V:|[nameLabel]|", metrics: metrics, views: views)

        addConstraint(NSLayoutConstraint(item: image, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        nameLabel.text = info.title
        image.image = info.image
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
        tapGesture.delaysTouchesBegan = false
        self.addGestureRecognizer(tapGesture)
    }
    func highlight() {
        self.backgroundColor = AppConstants.UI.MenuItemHighlight
        
    }
    
    func unhighlight() {
        self.backgroundColor = AppConstants.UI.MenuItemUnhighlight
    }

    func buttonTapped(_ sender: UITapGestureRecognizer) -> Void {
        delegate?.menuViewableDidTap(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var menuView: UIView { return self }
    var heightConstraints: [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AppConstants.UI.SideMenuItemHeight)
        ]
    }
}

class SpacerView: UIView , MenuViewable {
    var menuView: UIView { return self }
    var delegate: MenuViewableDelegate?
    
    var heightConstraints: [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AppConstants.UI.MenuInterItemSpacerViewHeightMin),
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AppConstants.UI.MenuInterItemSpacerViewHeightMax),
        ]
    }
    
    init() {
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SpacerConstantView: UIView , MenuViewable {
    static let bgColor = UIColor.clear
    var delegate: MenuViewableDelegate?
    var height: CGFloat
    var menuView: UIView { return self }
    var heightConstraints: [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height),
        ]
    }
    
    init(height: CGFloat) {
        self.height = height
        super.init(frame: CGRect.zero)
        self.backgroundColor = type(of: self).bgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class SpacerElasticView: SpacerView {
    override var heightConstraints: [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AppConstants.UI.MenuElasticSpacerViewMinHeight),
        ]
    }
}

class SideMenuViewController: UIViewController, MenuViewableDelegate {
    var items: [MenuViewable]!
    var scrollView: UIScrollView!
    var selectedIdentifier: SideMenuIdentifier? {
        willSet {
            if let selectedIdentifier = selectedIdentifier {
                getItemViewWithIdentifier(selectedIdentifier)?.unhighlight()
            }
        }
        didSet {
            if let selectedIdentifier = selectedIdentifier {
                getItemViewWithIdentifier(selectedIdentifier)?.highlight()
            }
        }
    }
    weak var delegate: SideMenuViewControllerDelegate?
    
    func viewOfType(_ classType: UIView.Type) -> [MenuViewable] {
        var it: [MenuViewable] = []
        for sv in self.items where type(of: sv) == classType {
            it.append(sv)
        }
        return it
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        items = [
            SpacerConstantView(height: max(self.topLayoutGuide.length, UIApplication.shared.statusBarFrame.height)),
            ProfileHeaderView(delegate: self),
            SpacerElasticView(),
            SideMenuItemView(id: SideMenuIdentifier.discovery, delegate: self),
            SpacerView(),
            SideMenuItemView(id: SideMenuIdentifier.myZones, delegate: self),
            SpacerView(),
            SideMenuItemView(id: SideMenuIdentifier.favourites, delegate: self),
            SpacerView(),
            SideMenuItemView(id: SideMenuIdentifier.explore, delegate: self),
            SpacerElasticView(),
            SideMenuItemView(id: SideMenuIdentifier.logout, delegate: self),
            SpacerElasticView()
        ]
        
        do {
            let grad = SideMenuGradientView()
            grad.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(grad)
            
            let views: [String: AnyObject] = ["grad": grad, "parent": view]
            view.addConstraint("H:|[grad(==parent)]|", metrics: nil, views: views)
            view.addConstraint("V:|[grad(==parent)]|", metrics: nil, views: views)
        }
        
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.backgroundColor = UIColor.clear
        scroll.scrollsToTop = false
        view.addSubview(scroll)
        scrollView = scroll
        
        let contentView = UIView()
        contentView.backgroundColor = UIColor.clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(contentView)
        
        do {
            let views: [String: AnyObject] = ["scroll": scroll, "content":contentView, "parent": view]
            view.addConstraint("H:|[scroll(==parent)]|", metrics: nil, views: views)
            view.addConstraint("V:|[scroll]|", metrics: nil, views: views)
            view.addConstraint("H:|[content(==scroll)]|", metrics: nil, views: views)
            view.addConstraint("V:|[content(>=scroll)]|", metrics: nil, views: views)
        }
        
        // layout vertically where (width == 100% and height >= 100%) of this ViewController's view
        var lastView: UIView?
        for item in items {
            print(item)
            item.menuView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(item.menuView)
            
            // H:|-[(items)]-|
            contentView.addConstraints(item.menuView, attributes: .leading, .trailing, .width)
            contentView.addConstraints(item.heightConstraints)
            
            if let lastView = lastView {
                // V:[item2][item3][item4]
                contentView.addConstraint(NSLayoutConstraint(item: item.menuView, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 0))
            } else {
                // V:|[item1]
                contentView.addConstraints(item.menuView, attributes: .top)
            }
            lastView = item.menuView
        }
        // V:[item4][last]|
        contentView.addConstraints(lastView!, attributes: .bottom)
        
        //// instances with same class will have equal height constraint
        let viewTypes: [UIView.Type] = items.map { type(of: $0.menuView) }
        for type in viewTypes {
            let vs = viewOfType(type)
            let first = vs.first!
            for child in vs.dropFirst() {
                let lay = NSLayoutConstraint(item: child.menuView, attribute: .height, relatedBy: .equal, toItem: first.menuView, attribute: .height, multiplier: 1, constant: 0)
                contentView.addConstraint(lay)
            }
        }
        
        loadUserProfile()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AppConstants.Notifications.UserProfileUpdated), object: nil, queue: OperationQueue.main) { [weak self](n) -> Void in
            self?.loadUserProfile()
        }
        
        if let old = selectedIdentifier {
            self.getItemViewWithIdentifier(old)?.highlight()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func menuViewableDidTap(_ viewable: MenuViewable) {
        if let sideMenu = viewable.menuView as? SideMenuItemView {
            if let old = selectedIdentifier {
                self.getItemViewWithIdentifier(old)?.unhighlight()
            }
            sideMenu.highlight()
            Delay(0.05) {
                self.delegate?.menuViewController(self, didSelectItem: sideMenu, identifier: sideMenu.id)
                self.selectedIdentifier = sideMenu.id
            }
        } else if let profile = viewable.menuView as? ProfileHeaderView {
            selectedIdentifier = nil
            self.delegate?.menuViewController(self, didTapOnProfileView: profile, profile: profile.user)
        }
    }
    
    func animationForOpening(_ completion: ((Bool)->Void)?) {
        scrollView.transform = CGAffineTransform(translationX: -self.view.frame.size.width/2.0, y: 0)
        if let old = selectedIdentifier {
            self.getItemViewWithIdentifier(old)?.highlight()
        }
        UIView.animate(withDuration: 0.33, delay: 0.1, options: UIViewAnimationOptions(rawValue: 0), animations: {
            self.scrollView.transform = CGAffineTransform.identity
            }, completion: completion)
    }
    
    func animationForClosing(_ completion: ((Bool)->Void)?) {
        self.scrollView.transform = CGAffineTransform.identity
        UIView.animate(withDuration: 0.33, delay: 0.1, options: UIViewAnimationOptions(rawValue: 0), animations: {
            self.scrollView.transform = CGAffineTransform(translationX: -self.view.frame.size.width/2.0, y: 0)
            }, completion: completion)
    }
    
    func loadUserProfile() {
        let userProfile = self.viewOfType(ProfileHeaderView.self).first as? ProfileHeaderView
        userProfile?.userBtn.startAnimatingBorder()
        _ = UserRequest.getSelf { (user, error) -> Void in
            OperationQueue.main.addOperation {
                userProfile?.user = user
                if let image = user?.profile?.image {
                    _ = ImageRequest.download(image, nil, ImageSize._100) { (image, error) -> Void in
                        if let img = image {
                            OperationQueue.main.addOperation {
                                userProfile?.userBtn.setImage(img, for: UIControlState.normal)
                                userProfile?.userBtn.stopAnimatingBorder()
                            }
                        } else {
                            userProfile?.userBtn.stopAnimatingBorder()
                        }
                    }.execute()
                } else {
                    userProfile?.userBtn.stopAnimatingBorder()
                }
            }
        }.execute()
    }
    
    func getItemViewWithIdentifier(_ identifier:SideMenuIdentifier) -> SideMenuItemView? {
        for itemView in items {
            if let item = itemView.menuView as? SideMenuItemView , item.id.rawValue == identifier.rawValue {
                return item
            }
        }
        return nil
    }

}

class SideMenuGradientView: UIView {
    override class var layerClass : AnyClass {
        return CAGradientLayer.self
    }
    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    fileprivate func commonInit() {
        let gradientLayer = self.layer as! CAGradientLayer
        gradientLayer.colors = [
            
            UIColor(red: 0.153, green: 0.404, blue: 0.627, alpha: 1).cgColor,
            UIColor(red: 0.149, green: 0.663, blue: 0.878, alpha: 1).cgColor,
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
