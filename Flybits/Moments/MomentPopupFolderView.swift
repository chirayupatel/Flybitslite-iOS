//
//  MomentPopupFolderView.swift
//  Flybits
//
//  Created by chu on 2015-09-03.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

protocol MomentPopupFolderViewDelegate : class {
    func popupFolderView(view:MomentPopupFolderView, presentingView:UIView, didSelectMoment:Moment, index:NSIndexPath)
}

class MomentPopupFolderView: UIView {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!

    weak var delegate: MomentPopupFolderViewDelegate?

    var moments: [Moment] = [] {
        didSet {
            collectionViewProvider.moments = moments

            if collectionView != nil {
                collectionView.reloadData()
            }
        }
    }

    private lazy var collectionViewProvider: MomentPopupFolderCollectionViewProvider = MomentPopupFolderCollectionViewProvider(parent:self)

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.delegate = collectionViewProvider
        collectionView.dataSource = collectionViewProvider
    }

}

 class MomentPopupFolderCollectionViewProvider : NSObject, UICollectionViewDataSource, UICollectionViewDelegate {

    weak var parentView: MomentPopupFolderView?
    var moments: [Moment] = []


    init(parent:MomentPopupFolderView) {
        self.parentView = parent
    }

    @objc func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return moments.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("moments", forIndexPath: indexPath) as! MomentCollectionViewCell

        let moment = moments[indexPath.row]
        cell.textLabel.text = moment.name.value

        return cell
    }

    @objc func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {

            let view =  collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "momentHeader", forIndexPath: indexPath)

            if let label = view.viewWithTag(1) as? UILabel {
                label.text = "\(moments.count) moments"
            }

            return view
        }
        return UICollectionReusableView()
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = max(0, (collectionView.contentSize.width - layout.sectionInset.left - layout.sectionInset.right - (layout.minimumInteritemSpacing * 3))/3.0 )

        return CGSize(width: width, height: width)
    }

//    @objc func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
//
//        guard indexPath.section == 1 else { return }
//
//        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? MomentContainerCollectionViewCell {
//            //            cell.expand(!cell.isExpanded, animated: true)
//        }
//    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)

        let moment = moments[indexPath.row]
        if let parentView = parentView {
            parentView.delegate?.popupFolderView(parentView, presentingView: collectionView, didSelectMoment: moment, index: indexPath)
        }
    }
    
}


