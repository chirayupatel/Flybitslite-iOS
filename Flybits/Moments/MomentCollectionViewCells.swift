//
//  MomentCollectionViewLayout.swift
//  Flybits
//
//  Created by Archu on 2016-03-09.
//  Copyright © 2016 Flybits. All rights reserved.
//

import Foundation
import UIKit

protocol AVCollectionReusableCell : class {
    static var reuseID: String { get }
    static var nib: UINib { get }
    static func registerNib(_ collectionView: UICollectionView, kind:String)
    static func registerClass(_ collectionView: UICollectionView, kind:String)
}

extension AVCollectionReusableCell {
    static var nib: UINib {
        let n = UINib(nibName: reuseID, bundle: nil)
        return n
    }
    static func registerNib(_ collectionView: UICollectionView, kind:String) {
        collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseID)
    }
    static func registerClass(_ collectionView: UICollectionView, kind:String) {
        collectionView.register(self, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseID)
    }
}

extension UICollectionReusableView : AVCollectionReusableCell {
    static var reuseID: String {
        return "\(self)"
    }
}
