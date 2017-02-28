//
//  ProfileThemedLabel.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-13.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

@IBDesignable
class ProfileThemedLabel: UILabel {

    @IBInspectable var primary: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
//        print(text as Any)
    }

    func commonInit() {
        if #available(iOS 9.0, *) {
            font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title3)
        } else {
            // Fallback on earlier versions
            font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)

        }
        if primary {
            textColor = Theme.primary.labelTextColor
        } else {
            textColor = Theme.secondary.labelTextColor
        }
    }
}
