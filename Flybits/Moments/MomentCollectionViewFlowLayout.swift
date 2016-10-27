//
//  MomentCollectionViewFlowLayout.swift
//  Flybits
//
//  Created by chu on 2015-09-01.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

protocol MomentCollectionViewDelegateFlowLayout : class {
    func collectionView(_ collectionViewLayout: MomentCollectionViewFlowLayout, collectionViewHeaderSizeForIndexPath indexPath: IndexPath, kind: String) -> CGSize
    func collectionView(_ collectionViewLayout: MomentCollectionViewFlowLayout, referenceHeaderSizeForIndexPath indexPath: IndexPath, kind: String) -> CGSize
    func collectionView(_ collectionViewLayout: MomentCollectionViewFlowLayout, referenceFooterSizeForIndexPath indexPath: IndexPath, kind: String) -> CGSize
    func collectionViewNumberOfReusableHeaderViews(_ collectionViewLayout: MomentCollectionViewFlowLayout) -> Int
}

let UICollectionElementKindHeaderReusable = "UICollectionElementKindHeaderReusable" // header for whole collection view
let UICollectionElementKindCell = "UICollectionElementKindCell" // each item cell

private let kDefaultSpacing: CGFloat = 10
class MomentCollectionViewFlowLayout : UICollectionViewLayout {

    fileprivate var _numColumns: CGFloat        = 3
    
    var itemHeightRatio: CGFloat            = 1.25
    var sectionFooterSize: CGSize           = CGSize(width: 0, height: 0)
    var sectionHeaderSize: CGSize           = CGSize(width: 0, height: 0)
    var sectionInset: UIEdgeInsets          = UIEdgeInsetsMake(kDefaultSpacing, kDefaultSpacing, kDefaultSpacing, kDefaultSpacing)
    var sectionSupplementaryViewInset       = UIEdgeInsets.zero
    
    var suplementaryViewAttributes          = [IndexPath: [String: UICollectionViewLayoutAttributes]]()
    var cellsAttributes                     = [IndexPath: UICollectionViewLayoutAttributes]()
    var verticalItemSeparation: CGFloat     = kDefaultSpacing
    var horizontalItemSeparation: CGFloat   = kDefaultSpacing
    
    fileprivate var delegate: MomentCollectionViewDelegateFlowLayout? {
        get {
            return self.collectionView?.delegate as? MomentCollectionViewDelegateFlowLayout
        }
    }
    
    fileprivate var contentSize: CGSize         = CGSize.zero
    
    var numOfColumns: Int {
        get {
            return Int(max(1, _numColumns))
        }
        set(v) {
            _numColumns = CGFloat(v)
        }
    }
    
    override func prepare() {
        super.prepare()
        
        suplementaryViewAttributes.removeAll()
        
        var attribReusableHeader    = [IndexPath: [String: UICollectionViewLayoutAttributes]]()
        var attribCellItems         = [IndexPath: UICollectionViewLayoutAttributes]()
        
        let cv = collectionView!
        
        let totalWidth = cv.frame.size.width - (cv.contentInset.horizontal()) - (sectionInset.horizontal()) - ((numOfColumns.e_CGFloat - 1) * horizontalItemSeparation)
        let itemWidth = totalWidth / numOfColumns.e_CGFloat
        let totalHeaderWidth = cv.frame.size.width - cv.contentInset.horizontal()
        
        var ySoFar: CGFloat = 0 //cv.contentInset.top
        
        // reusable collection view header_views
        // UICollectionElementKindHeaderReusable
        let numOfCollectionHeaderViews = delegate?.collectionViewNumberOfReusableHeaderViews(self) ?? 0
        for i in 0 ..< numOfCollectionHeaderViews {
            do {
                let index = IndexPath(item: i, section: 0)
                let attrib = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindHeaderReusable, with: index)
                if let h = delegate?.collectionView(self, collectionViewHeaderSizeForIndexPath: index, kind: UICollectionElementKindHeaderReusable) , h.height > 0 {
                    attrib.frame = CGRect(origin: CGPoint(x: 0, y: ySoFar), size: CGSize( width: h.width == 0 ? cv.frame.width : h.width, height: h.height))
                    
                    var layoutItem = attribReusableHeader[index] ?? [String:UICollectionViewLayoutAttributes]()
                    layoutItem[UICollectionElementKindHeaderReusable] = attrib
                    attribReusableHeader[index] = layoutItem
                    
                    ySoFar += attrib.frame.height
                }
            }
        }
        
        var xSoFar: CGFloat = cv.contentInset.left
        
        for section in 0 ..< cv.numberOfSections {
            ySoFar += sectionInset.top
            xSoFar += sectionInset.left
            
            do { // sectionTop
                let index = IndexPath(item: 0, section: section)
                if let h = delegate?.collectionView(self, referenceHeaderSizeForIndexPath: index, kind: UICollectionElementKindSectionHeader) , h.height > 0 {
                    let attrib = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: index)
                    attrib.frame = CGRect(origin: CGPoint(x: xSoFar + sectionSupplementaryViewInset.left, y: ySoFar + sectionSupplementaryViewInset.top), size: CGSize( width: (h.width == 0 ? totalHeaderWidth : h.width) - sectionSupplementaryViewInset.right - sectionSupplementaryViewInset.left, height: h.height))
                    var layoutItem = attribReusableHeader[index] ?? [String:UICollectionViewLayoutAttributes]()
                    layoutItem[UICollectionElementKindSectionHeader] = attrib
                    attribReusableHeader[index] = layoutItem
                    
                    ySoFar += (attrib.frame.height + sectionSupplementaryViewInset.bottom)
                    ySoFar += sectionSupplementaryViewInset.vertical()
                }
            }
            let totalItemInSection = cv.numberOfItems(inSection: section)
            let numOfRows = ceil((CGFloat(totalItemInSection) / CGFloat(numOfColumns)))
            
            var verticalItemSeparationAdded = false
            // each cells in a grid
            for row in 0 ..< Int(numOfRows) {
                var x = xSoFar + cv.contentInset.left
                for col in 0 ..< numOfColumns {
                    let itemIndex = (numOfColumns * row) + col
                    if itemIndex >= totalItemInSection {
                        break
                    }
                    do { // row of items
                        let index = IndexPath(item: itemIndex, section: section)
                        let attrib = UICollectionViewLayoutAttributes(forCellWith: index)
                        attrib.frame = CGRect(origin: CGPoint(x: x, y: ySoFar), size: CGSize( width: itemWidth, height: itemWidth * itemHeightRatio))
                        attribCellItems[index] = attrib
                        x += attrib.frame.width + horizontalItemSeparation
                    }
                }
                ySoFar += ((itemWidth * itemHeightRatio) + (verticalItemSeparation))
                verticalItemSeparationAdded = true
            }
            
            if verticalItemSeparationAdded {
                ySoFar -= verticalItemSeparation
            }
            
            ySoFar += sectionInset.bottom
            
            do { // sectionBottom
                let index = IndexPath(item: 0, section: section)
                if let h = delegate?.collectionView(self, referenceFooterSizeForIndexPath: index, kind: UICollectionElementKindSectionHeader) , h.height > 0 {
                    let attrib = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: index)
                    let origin = CGPoint(x: xSoFar + sectionSupplementaryViewInset.left, y: ySoFar + sectionSupplementaryViewInset.top)
                    let size   = CGSize( width: (h.width == 0 ? totalHeaderWidth : h.width) - sectionSupplementaryViewInset.horizontal() - sectionInset.horizontal(), height: h.height)
                    attrib.frame = CGRect(origin: origin, size: size)
                    
                    var layoutItem = attribReusableHeader[index] ?? [String:UICollectionViewLayoutAttributes]()
                    layoutItem[UICollectionElementKindSectionFooter] = attrib
                    attribReusableHeader[index] = layoutItem
                    ySoFar += (attrib.frame.height + sectionSupplementaryViewInset.bottom)
                    ySoFar += sectionSupplementaryViewInset.vertical()
                }
            }
            ySoFar += sectionInset.bottom
            xSoFar -= sectionInset.left
        }
        
        cellsAttributes = attribCellItems
        suplementaryViewAttributes = attribReusableHeader
        
        contentSize = CGSize(width: totalWidth, height: ySoFar)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cellsAttributes[indexPath]
    }
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return suplementaryViewAttributes[indexPath]![elementKind]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var items = super.layoutAttributesForElements(in: rect) ?? [UICollectionViewLayoutAttributes]()
        for indexPaths in suplementaryViewAttributes {
            for (_, v) in indexPaths.1 where rect.intersects(v.frame) {
                items.append(v)
            }
        }
        
        for (_, attrib) in cellsAttributes where rect.intersects(attrib.frame){
            items.append(attrib)
        }
        
        return items
    }
    
    override var collectionViewContentSize : CGSize {
        return contentSize
//        return CGSizeMake(max(contentSize.width, collectionView!.frame.width),
//        max(contentSize.height, collectionView!.frame.height))
    }
    
}

extension UIEdgeInsets {
    func horizontal() -> CGFloat {
        return left + right
    }
    func vertical() -> CGFloat {
        return top + bottom
    }
    
}

extension Int {
    var e_CGFloat : CGFloat {
        return CGFloat(self)
    }
}
