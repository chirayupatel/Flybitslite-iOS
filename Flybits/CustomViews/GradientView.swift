//
//  GradientView.swift
//  Flybits
//
//  Created by Terry Latanville on 2015-10-30.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class GradientView: UIView {
    @IBInspectable var gradientStart: UIColor = UIColor.clear {
        didSet {
            if superview != nil {
                updateGradient()
            }
        }
    }

    @IBInspectable var gradientEnd: UIColor = UIColor.clear {
        didSet {
            if superview != nil {
                updateGradient()
            }
        }
    }

    // MARK: - Lifecycle Functions
    override func awakeFromNib() {
        updateGradient()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            updateGradient()
        }
        super.willMove(toSuperview: newSuperview)
    }

    // Functions
    func updateGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [gradientStart, gradientEnd]
        
        layer.insertSublayer(gradient, at: 0)
    }
}
