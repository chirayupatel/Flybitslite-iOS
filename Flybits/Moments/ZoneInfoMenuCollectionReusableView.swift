//
//  ZoneInfoMenuCollectionReusableView.swift
//  collectionviewlayouts
//
//  Created by Archu on 2016-03-09.
//  Copyright © 2016 flybits. All rights reserved.
//

import UIKit

class ZoneInfoMenuCollectionReusableView: UICollectionReusableView {
    enum ButtonType {
        case favourite
        case share
        case distance
    }
    
    @IBOutlet weak var btnFavourite: ButtonSizableImage!
    @IBOutlet weak var btnShare: ButtonSizableImage!
    @IBOutlet weak var btnDistance: ButtonSizableImage!
    weak var delegate: MomentZoneInfoHeaderViewDelegate?
    
    func updateFavouriteButton(_ isFavourited:Bool) {
        btnFavourite.setImage(UIImage(named: isFavourited ? "ic_favorite_star_w" : "ic_favorite_star_outline_w"), for: UIControlState())
    }
    
    func updateFavouriteCount(_ count:Int?) {
        if let count1 = count {
            self.btnFavourite.setTitle("\(count1)", for: UIControlState())
        } else {
            self.btnFavourite.setTitle("-", for: UIControlState())
        }
    }
    @IBAction func buttonTapped(_ sender:UIButton) {
        switch sender {
        case btnFavourite:
            delegate?.momentZoneInfoHeaderView(self, tappedButton: sender, type: .favourite)
        case btnShare:
            delegate?.momentZoneInfoHeaderView(self, tappedButton: sender, type: .share)
        case btnDistance:
            delegate?.momentZoneInfoHeaderView(self, tappedButton: sender, type: .distance)
        default: break
        }
    }
}

protocol MomentZoneInfoHeaderViewDelegate : class {
    func momentZoneInfoHeaderView(_ view:ZoneInfoMenuCollectionReusableView, tappedButton:UIButton, type:ZoneInfoMenuCollectionReusableView.ButtonType)
}

