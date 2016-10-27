//
//  ImagedEmptyView.swift
//  Flybits
//
//  Created by Archuthan Vijayaratnam on 11/12/15.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class ImagedEmptyView: UIView {
    
    fileprivate var imageView: UIImageView = UIImageView()
    fileprivate var label: UILabel = UILabel()
    
    fileprivate var imgWidthConstraint: NSLayoutConstraint!
    fileprivate var imgHeightConstraint: NSLayoutConstraint!
    
    init(){
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    fileprivate func commonInit() {
        
        self.backgroundColor = UIColor(red: 0.9569, green: 0.9569, blue: 0.9569, alpha: 1.0) /* #f4f4f4 */

        let img = imageView
        img.contentMode = UIViewContentMode.scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        addSubview(img)

        let lbl = label
        lbl.text = ""
        lbl.numberOfLines = 0
        lbl.textColor = UIColor.black
        lbl.textAlignment = NSTextAlignment.center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lbl)

        self.addConstraint(NSLayoutConstraint(item: img, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: img, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        imgHeightConstraint = NSLayoutConstraint(item: img, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        imgWidthConstraint = NSLayoutConstraint(item: img, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        
        self.addConstraint( imgWidthConstraint )
        self.addConstraint( imgHeightConstraint )
        
        self.addConstraint( NSLayoutConstraint(item: lbl, attribute: .top, relatedBy: .equal, toItem: img, attribute: .bottom, multiplier: 1, constant: 10))
        self.addConstraint(NSLayoutConstraint(item: lbl, attribute: .centerX, relatedBy: .equal, toItem: img, attribute: .centerX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: lbl, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 20))
        self.addConstraint(NSLayoutConstraint(item: lbl, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -20))
    }

    func updateLabel(_ string:String?) {
        label.text = string
        label.isHidden = string == nil
    }
    
    func updateImage(_ image:UIImage?) {
        imageView.image = image
        imageView.isHidden = image == nil
    }
    
    func updateImageSize(_ size:CGSize) {
        imgWidthConstraint.constant = size.width
        imgHeightConstraint.constant = size.height
        self.updateConstraintsIfNeeded()
    }
}
