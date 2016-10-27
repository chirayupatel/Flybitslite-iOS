//
//  UserAvatar.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-16.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class UserAvatar: UIButton {
    
    var image: UIImage? {
        didSet {
            if image != nil {
                setImage(image, for: UIControlState())
            } else {
                setImage(Theme.primary.imageDefaultAvatar, for: UIControlState())
            }
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        themeIt()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        themeIt()
    }

    func themeIt() {
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = bounds.width/2
    }
    
    func startAnimatingBorder() {
        
        let group = CAAnimationGroup()
        group.duration = 1
        group.repeatCount = MAXFLOAT
        group.autoreverses = true

        let anim = CAKeyframeAnimation(keyPath: "borderWidth")
        anim.values = [1, 2, 3]
        
        let colors = CAKeyframeAnimation(keyPath: "borderColor")
        colors.values = [UIColor(red: 0, green: 0.7765, blue: 0.1882, alpha: 1.0).cgColor, UIColor(red: 1, green: 0.5765, blue: 0.7882, alpha: 1.0).cgColor, UIColor(red: 0, green: 0.1549, blue: 0.898, alpha: 1.0).cgColor]
        
        group.animations = [anim, colors]
        layer.add(group, forKey: "group")
    }
    
    func stopAnimatingBorder() {
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        layer.removeAnimation(forKey: "group")
    }
}
