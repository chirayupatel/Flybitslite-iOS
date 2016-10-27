//
//  YoutubeVideoCollectionViewCell.swift
//  Flybits
//
//  Created by chu on 2015-10-18.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class YoutubeVideoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var profileInfoView: UIView!
    @IBOutlet weak var handleBarView: UIView!
    @IBOutlet weak var revealedView: UIView!

    var delegate: YoutubeVideoCollectionViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(YoutubeVideoCollectionViewCell.tapGestureActivated(_:))))
        scrollView.isScrollEnabled = false
    }

    func tapGestureActivated(_ sender:UITapGestureRecognizer) {
        delegate?.collectionViewCellDidTap(self)
    }

    func setImage(_ image:String) -> Operation {
        return BlockOperation(block: { () -> Void in

            let data = try! Data(contentsOf: URL(string: image)!)
            let img = UIImage(data: data)
            OperationQueue.main.addOperation({
                self.imageView!.image = img
            })
        })
    }
}

protocol YoutubeVideoCollectionViewCellDelegate : class {
    func collectionViewCellDidTap(_ cell:YoutubeVideoCollectionViewCell) // only if uicollectionview's didTap... callback doesn't handle it
}


extension YoutubeVideoCollectionViewCell : UIScrollViewDelegate {

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        if velocity.x < 0 || scrollView.panGestureRecognizer.translation(in: scrollView).x > 0 {
            targetContentOffset.pointee.x = 0
        } else if velocity.y > 0 || scrollView.panGestureRecognizer.translation(in: scrollView).x < 0{
            targetContentOffset.pointee.x = revealedView.frame.width
        }

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity.x, options: UIViewAnimationOptions(), animations: { () -> Void in
            scrollView.contentOffset = targetContentOffset.pointee
            }, completion: nil)
        
    }
}
