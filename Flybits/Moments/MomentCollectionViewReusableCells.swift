//
//  MomentCollectionViewReusableCells.swift
//  Flybits
//
//  Created by Archu on 2016-03-10.
//  Copyright © 2016 Flybits. All rights reserved.
//

import Foundation
import UIKit

class MomentLoadingFooterCollectionViewCell: UICollectionReusableView {
 
    fileprivate var loadingView = UIActivityIndicatorView()
    fileprivate var loadingViewWidthConstraint: NSLayoutConstraint!
    fileprivate var loadingViewHeightConstraint: NSLayoutConstraint!
    var text = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    var loading: Bool = false {
        didSet {
            if loading {
                loadingView.startAnimating()
                loadingViewWidthConstraint.constant = 40
                loadingViewHeightConstraint.constant = 40
            } else {
                loadingView.stopAnimating()
                loadingViewWidthConstraint.constant = 0
                loadingViewHeightConstraint.constant = 0
            }
        }
    }
    
    func commonInit() {
        addSubview(loadingView)
        addSubview(text)
        
        text.textColor = UIColor.darkGray
        text.textAlignment = NSTextAlignment.center
        
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        text.translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["loading":loadingView, "text":text] as [String : Any]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[loading][text]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[text]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        
        loadingViewWidthConstraint = NSLayoutConstraint(item: loadingView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        loadingViewHeightConstraint = NSLayoutConstraint(item: loadingView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        addConstraints([loadingViewHeightConstraint, loadingViewWidthConstraint])
        
        addConstraint(NSLayoutConstraint(item: loadingView, attribute: .centerY, relatedBy: .equal, toItem: text, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        print(layoutAttributes)
    }
}

