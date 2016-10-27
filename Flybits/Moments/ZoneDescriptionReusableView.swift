//
//  ZoneDescriptionReusableView.swift
//  collectionviewlayouts
//
//  Created by Archu on 2016-03-09.
//  Copyright © 2016 flybits. All rights reserved.
//

import UIKit

protocol ZoneDescriptionReusableViewDelegate : class {
    func zoneDescriptionReusableView(_ view: ZoneDescriptionReusableView, tappedMoreButton: UIButton)
}

private let kNoDescriptionText = "Description not available\n\n\n"

class ZoneDescriptionReusableView: UICollectionReusableView {
    
    var zoneDescription: String? {
        didSet {
            updateView()
        }
    }
    
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.black.cgColor,
            UIColor.clear.cgColor,
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.75)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        return gradientLayer
    }()
    lazy fileprivate var expandedGradientColors = [UIColor.black.cgColor, UIColor.clear.cgColor]
    lazy fileprivate var shrinkedGradientColors = [UIColor.clear.cgColor, UIColor.clear.cgColor]

    
    weak var delegate: ZoneDescriptionReusableViewDelegate?
    
    var expanded: Bool = false {
        didSet {
            updateView()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.addSublayer(gradientLayer)
        updateView()
    }

    func expand(_ expand: Bool) -> CGFloat {
        let view = self
        if view.descriptionLabel?.text == nil {
            view.descriptionLabel?.text = kNoDescriptionText
        }
        
        if !expand {
            // shrink
            view.descriptionLabel.numberOfLines = 4
            view.descriptionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        } else {
            // expand
            view.descriptionLabel.numberOfLines = 0
            view.descriptionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        }
        view.descriptionLabel.invalidateIntrinsicContentSize()
        
        var newBounds = view.descriptionLabel.bounds
        newBounds.size.height = CGFloat.greatestFiniteMagnitude
        let newSize = view.descriptionLabel.textRect(forBounds: newBounds, limitedToNumberOfLines: view.descriptionLabel.numberOfLines)
        return newSize.height
    }
    
    func toggleDescriptionHeight() -> CGFloat {
        let view = self
        if view.descriptionLabel.numberOfLines == 0 {
            view.expanded = false
            return expand(false)
        } else {
            view.expanded = true
            return expand(true)
        }
    }
    
    func updateView() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        descriptionLabel?.text = "\(zoneDescription ?? "")\n"
        self.updateConstraintsIfNeeded()
        gradientLayer.colors = !expanded ? expandedGradientColors : shrinkedGradientColors
        _ = expand(expanded)
        
        CATransaction.commit()
    }
    
    @IBAction func moreButtonTapped(_ sender: UIButton) {
        descriptionLabel?.invalidateIntrinsicContentSize()
        delegate?.zoneDescriptionReusableView(self, tappedMoreButton: sender)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
    }
}

