//
//  MomentZoneInfoHeaderView.swift
//  Flybits
//
//  Created by chu on 2015-08-31.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

protocol MomentZoneInfoTitleHeaderViewDelegate : class {
    func infoTitleHeaderView(_ view: MomentZoneInfoHeaderView, didTapButton: UIButton?)
}
class MomentZoneInfoHeaderView: UIView {

    @IBOutlet weak var labelZoneName: UILabel!
    
    weak var delegate: MomentZoneInfoTitleHeaderViewDelegate?
    @IBOutlet weak var constraintBtnMoreWidth: NSLayoutConstraint?
    
    func updateName(_ name:String?) {
        self.labelZoneName?.text = name
    }

    @IBAction func moreInfoButtonTapped(_ sender: UIButton?) {
        delegate?.infoTitleHeaderView(self, didTapButton: sender)
    }
}

