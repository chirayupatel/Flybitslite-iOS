//
//  LoadingView.swift
//  Flybits
//
//  Created by chu on 2015-09-04.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class LoadingView: UIView {

    fileprivate lazy var imageView:UIImageView = {
        let imgView = UIImageView()

        var imgs = [UIImage]()

        for x in 0...66 {
            let name = NSString(format: "loader_blue_000%.2d", x)
            imgs.append(UIImage(named: name as String)!)
        }
        imgView.animationImages = imgs
        imgView.animationDuration = 2
        imgView.startAnimating()

        return imgView
    }()

    var loading: Bool = true {
        didSet {
            if loading {
                imageView.startAnimating()
            } else {
                imageView.stopAnimating()
            }
        }
    }
    
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

        self.backgroundColor = UIColor.white

        let img = imageView

        addSubview(img)
        img.translatesAutoresizingMaskIntoConstraints = false


        NSLayoutConstraint.equal(.centerX, view1: img, asView: self)
        NSLayoutConstraint.equal(.centerY, view1: img, asView: self)


        self.addConstraint( NSLayoutConstraint(item: img, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60) )
        self.addConstraint( NSLayoutConstraint(item: img, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60) )
    }
    
}
