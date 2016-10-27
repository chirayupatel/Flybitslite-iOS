//
//  UserListCollectionViewFlowLayout.swift
//  Flybits
//
//  Created by chu on 2015-10-17.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

/**
    Note: Size is automatically overriden to be collectionView's width
*/
class UserListCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        if let collectionView = collectionView {
            self.itemSize = CGSize(width: collectionView.frame.width, height: self.itemSize.height)
        }
        super.prepare()
    }
}
