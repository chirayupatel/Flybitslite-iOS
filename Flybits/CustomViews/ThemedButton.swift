//
//  ThemedButton.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit


@IBDesignable
class ThemedButton: UIButton {

    @IBInspectable var primaryTheme: Bool? {
        didSet {
            setupTheme()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        layer.cornerRadius = Theme.currentTheme.buttonCornerRadius
            setupTheme()
    }
    
    fileprivate func setupTheme() {
        if let primaryTheme = primaryTheme  {
            let state = UIControlState()
            
            if primaryTheme {
                setTitleColor(Theme.primary.buttonTextColor(state), for: state)
                backgroundColor = Theme.primary.buttonBackgroundColor(state)
            } else {
                self.setTitleColor(Theme.secondary.buttonTextColor(state), for: state)
                backgroundColor = Theme.secondary.buttonBackgroundColor(state)
            }
        }
    }

    override func setValue(_ value: Any?, forKey key: String) {
        if let value = value as? NSNumber , (key == "primaryTheme") {
            self.primaryTheme = value.boolValue
        } else if key == "primaryTheme" {
            self.primaryTheme = nil
        }
    }
}
