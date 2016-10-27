//
//  UserListCollectionViewSocialDelegate.swift
//  Flybits
//
//  Created by chu on 2015-10-17.
//  Copyright © 2015 Flybits. All rights reserved.
//

import Foundation
import UIKit


public enum UserListCollectionViewSocialItem {
    case facebook
    case twitter
    case linkedIn
    case instagram
}

open class UserListCollectionBaseCellView : UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var btnSocialFacebook: UIButton!
    @IBOutlet weak var btnSocialTwitter: UIButton!
//    @IBOutlet weak var btnSocialLinkedIn: UIButton!
    @IBOutlet weak var btnSocialInstagram: UIButton!

    var delegate: UserListCollectionViewDelegate?

    open func setImage(_ image:String) -> Operation {
        return BlockOperation(block: { () -> Void in
            if let url = URL(string: image), let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                OperationQueue.main.addOperation({
                    self.imageView!.image = img
                })
            }
        })
    }

    @IBAction func socialButtonTapped(_ sender: UIButton) {

        let item:UserListCollectionViewSocialItem?
        switch sender {
        case btnSocialFacebook: item = .facebook
        case btnSocialTwitter: item = .twitter
//        case btnSocialLinkedIn: item = .LinkedIn
        case btnSocialInstagram: item = .instagram
        default: item = nil
        }
        guard let socialItem = item else {
            return
        }
        delegate?.collectionViewCell(self, didTapOnButton: sender, item: socialItem)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        if let imageView = imageView {
            imageView.layer.cornerRadius = imageView.frame.size.height/2.0
            imageView.layer.masksToBounds = true
        }
    }
}

protocol UserListCollectionViewDelegate : class {
    func collectionViewCell(_ cell:UICollectionViewCell, didTapOnButton:UIButton, item: UserListCollectionViewSocialItem)
}
