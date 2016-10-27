//
//  ButtonSizableImage.swift
//  Flybits
//
//  Created by chu on 2015-08-24.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

private let Padding:CGFloat = 10

@IBDesignable
class ButtonSizableImage: UIButton {

    fileprivate lazy var indicator:UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        view.hidesWhenStopped = true
        return view
    }()

    var hideOnLoading = true

    var loading: Bool = false {
        didSet {
            if loading {
                indicator.startAnimating()
                self.isEnabled = false
                if hideOnLoading {
                    self.imageView?.isHidden = true
                    self.titleLabel?.isHidden = true
                }

            } else {
                indicator.stopAnimating()
                self.isEnabled = true
                if hideOnLoading {
                    self.imageView?.isHidden = false
                    self.titleLabel?.isHidden = false
                }
            }
            setNeedsLayout()
        }
    }

    @IBInspectable var imageSize: CGSize = CGSize.zero

    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(indicator)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

            imageView?.isHidden = loading
            titleLabel?.isHidden = loading

        indicator.frame = self.imageView?.frame ?? self.bounds
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let f = imageRect(forContentRect: contentRect)
        
        return CGRect(x: f.maxX + Padding, y: Padding, width: contentRect.maxX - contentRect.minX - (Padding * 2), height: contentRect.maxY - contentRect.minY - (Padding * 2))
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let originX = contentRect.origin.x + Padding
        let originY = contentRect.midY - (imageSize.height/2.0)
        return CGRect(x: originX, y: originY, width: imageSize.width, height: imageSize.height)
    }
}
