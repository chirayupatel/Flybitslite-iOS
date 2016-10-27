//
//  ZoneDetailedInfoCollectionViewCell.swift
//  Flybits
//
//  Created by Archuthan Vijayaratnam on 2016-05-24.
//  Copyright © 2016 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK


class ZoneDetailedInfoCollectionViewCell: ZoneCollectionViewCell {
    
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var userContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userProfileTapped))
        userContainerView.addGestureRecognizer(tapGesture)
    }
    
    override func setup(_ zone: Zone, index: IndexPath, zoneDistance: String, locale: Locale?) {
        super.setup(zone, index: index, zoneDistance: zoneDistance, locale: locale)
    }
    
    func updateUI(_ tags: [Tag], owner: User?, userImage: UIImage?) {
        self.tagLabel.attributedText = attribTagText(tags)
        self.userImageView.image     = userImage
        self.userLabel.text          = owner?.profile?.fullName
    }
    
    func attribTagText(_ tags: [Tag]) -> NSAttributedString {
        let tags = tags.filter({
            if let visibleTag = $0 as? VisibleTag {
                return visibleTag.visibility
            }
            return true
        })
        let attrib = NSMutableAttributedString()
        if !tags.isEmpty {
            attrib.append(NSAttributedString(string: "🔖"))
        }
        
        let attribDict = [
            NSBackgroundColorAttributeName: UIColor.orange,
            NSForegroundColorAttributeName: UIColor.white
        ]
        
        for t in tags {
            attrib.append(NSAttributedString(string: t.lite_tagValue, attributes: attribDict))
            attrib.append(NSAttributedString(string: " "))
        }
        
        if !tags.isEmpty {
            attrib.append(NSAttributedString(string: "\n"))
        }
        return attrib
    }
    
    @IBAction func userProfileTapped(_ sender: UITapGestureRecognizer) {
        delegate?.zoneCollectionViewCell(self, didTapOnView: sender.view!, type: .none, indexPath: indexPath, userInfo: userInfo)
    }
}

extension UserProfile {
    var fullName: String {
        print(firstname)
        print(lastname)
        let n = "\(firstname ?? "") \(lastname ?? "")"
        return n
    }
}

extension Tag {
    var lite_tagValue: String {
        if let tempValue = self.value?.value {
            return " \(tempValue) " //add padding on both side (hacky solution? yes)
        }
        return ""
    }
}
