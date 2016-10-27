//
//  ZoneItemCollectionViewCell.swift
//  Flybits
//
//  Created by chu on 2015-09-07.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit


protocol ZoneItemCollectionViewCellDelegate : class {
    func zoneCollectionViewCellDidSelect(cell:ZoneItemCollectionViewCell, indexPath:NSIndexPath, userInfo:AnyObject?)

    func zoneCollectionViewCell(cell:ZoneItemCollectionViewCell, didTapOnView:UIView, type:ZoneItemCollectionViewCell.ButtonType, indexPath:NSIndexPath, userInfo:AnyObject?)

}


private let LeftInset: CGFloat = 20
private var DefaultZoneImage = UIImage(named: "ic_zoneplaceholder")

class ZoneItemCollectionViewCell: UICollectionViewCell {

    var scrollView: UIScrollView!
    var leftContentContainerView: ZoneLeftContentView!
    var rightContentContainerView: ZoneRightContentView!

    var indexPath: NSIndexPath!
    var userInfo: AnyObject?
    weak var delegate: ZoneItemCollectionViewCellDelegate?

    private let maskLeftContentLayer = CAShapeLayer()
    private let maskRightContentLayer = CAShapeLayer()

    var isFavourited:Bool = false {
        didSet {
            leftContentContainerView.infoView.btnFavourites?.setImage(UIImage(named: isFavourited ? "ic_favorite_star_w" : "ic_favorite_star_outline_w"), forState: .Normal)
        }
    }

    private var pageNumber:Page = .ZoneImage {
        didSet {
            let page = CGFloat (pageNumber.rawValue) * scrollView.bounds.width
            scrollView.scrollRectToVisible(CGRectMake(page, scrollView.bounds.origin.y, scrollView.bounds.size.width, scrollView.bounds.height), animated: false)
        }
    }

    func page() -> Page {
        return pageNumber
    }

    func setPage(page:Page) {
        pageNumber = page
    }



    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.pagingEnabled = true
        scrollView.directionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = true
        leftContentContainerView = ZoneLeftContentView(frame: CGRectZero)
        leftContentContainerView.cell = self

        setImage(nil)

        rightContentContainerView = ZoneRightContentView(frame: CGRectZero)
        rightContentContainerView.cell = self

        addSubview(scrollView)
        scrollView.addSubview(leftContentContainerView)
        scrollView.addSubview(rightContentContainerView)

        let fillColor = UIColor.blackColor().CGColor
        maskLeftContentLayer.fillColor = fillColor
        leftContentContainerView.layer.mask = maskLeftContentLayer

        maskRightContentLayer.fillColor = fillColor
        rightContentContainerView.layer.mask = maskRightContentLayer

        let tapGesture1 = UITapGestureRecognizer(target: self, action: "tapGestureActivated:")
        scrollView.addGestureRecognizer(tapGesture1)

        layer.rasterizationScale = UIScreen.mainScreen().scale
        layer.shouldRasterize = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func tapGestureActivated(sender: UITapGestureRecognizer) {
        delegate?.zoneCollectionViewCellDidSelect(self, indexPath:indexPath, userInfo:userInfo)
    }

    func setNumOfFavourite(numOfFav:Int) {
        leftContentContainerView.infoView.btnFavourites.setTitle("\(numOfFav)", forState: UIControlState.Normal)
    }

    func setTitle(title:String?) {
        leftContentContainerView.infoView.titleLabel.text = title
    }

    func setZoneDescription(description:String?) {
        rightContentContainerView.textView.text = description
    }

    func setDistance(distance: String) {
//        leftContentContainerView.infoView.distanceContainerView
    }

    func setImage(image:UIImage?) {
        leftContentContainerView.imageView?.image = image ?? DefaultZoneImage
    }

    override func layoutSubviews() {
        super.layoutSubviews()


        scrollView.frame = self.contentView.bounds
        scrollView.contentSize = CGSizeMake((self.contentView.bounds.size.width * 2) + LeftInset, self.contentView.bounds.size.height)

        leftContentContainerView.frame = CGRectOffset(self.contentView.bounds, LeftInset * 2, 0)
        rightContentContainerView.frame = CGRectMake(leftContentContainerView.frame.maxX, self.contentView.bounds.minY, self.contentView.bounds.maxX - LeftInset, self.contentView.bounds.maxY)


        let cornerRadius: CGFloat = 6.0
        let size = CGSize(width: cornerRadius, height: cornerRadius)
        maskLeftContentLayer.frame = leftContentContainerView.bounds
        maskLeftContentLayer.path = UIBezierPath(roundedRect: maskLeftContentLayer.frame, byRoundingCorners: [UIRectCorner.TopLeft, UIRectCorner.BottomLeft], cornerRadii: size).CGPath

        maskRightContentLayer.frame = rightContentContainerView.bounds
        maskRightContentLayer.path = UIBezierPath(rect: maskRightContentLayer.frame).CGPath
    }

    enum ButtonType {
        case Favourite
        case Share
        case Distance
    }

    enum Page : Int {
        case ZoneImage
        case Description
    }
}


class ZoneLeftContentView: UIView {
    let ImageViewHeightRatio: CGFloat = 0.65
    var imageView : UIImageView!
    var infoView: ZoneLeftInfoView!
    weak var cell: ZoneItemCollectionViewCell! {
        didSet {
            infoView.cell = cell
        }
    }

    init() {
        fatalError("not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView = UIImageView()
        infoView = ZoneLeftInfoView(frame: CGRectZero)

        infoView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)

        addSubview(imageView)
        addSubview(infoView)
        self.backgroundColor = UIColor.purpleColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.frame = CGRectMake(self.bounds.minX, self.bounds.minY, self.bounds.width, self.bounds.height * ImageViewHeightRatio)

        infoView.frame = CGRectMake(imageView.frame.minX, imageView.frame.height, imageView.frame.maxX, self.bounds.height - imageView.frame.height)

    }
}

class ZoneLeftInfoView: UIView {
    private let MaxButtonWidth: CGFloat = 110
    private let ButtonHeight: CGFloat = 40
    private let ButtonOffset: CGFloat = 5

    var btnFavourites: ButtonSizableImage!
    var btnShare: ButtonSizableImage!
    var distanceContainerView: RandomColorView!
    var titleLabel: UILabel!
    weak var cell: ZoneItemCollectionViewCell!

    init() {
        fatalError("not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel = UILabel(frame: CGRectZero)
        btnFavourites = ButtonSizableImage(frame: CGRectZero)
        btnFavourites.imageSize = CGSizeMake(20, 20)
        btnShare = ButtonSizableImage(frame: CGRectZero)
        btnShare.imageSize = CGSizeMake(20, 20)
        distanceContainerView = RandomColorView(frame: CGRectZero)
        distanceContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "distanceContainerTapped:"))

        btnFavourites.addTarget(self, action: "btnTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        btnShare.addTarget(self, action: "btnTapped:", forControlEvents: UIControlEvents.TouchUpInside)

        addSubview(titleLabel)
        addSubview(btnFavourites)
        addSubview(distanceContainerView)
        addSubview(btnShare)
    }

    func distanceContainerTapped(sender:UIGestureRecognizer) {
        cell.delegate?.zoneCollectionViewCell(cell, didTapOnView: sender.view!, type: .Distance, indexPath: cell.indexPath, userInfo: cell.userInfo)
    }

    func btnTapped(sender:UIButton) {
        if case btnFavourites = sender {
            cell.delegate?.zoneCollectionViewCell(cell, didTapOnView: sender, type: .Favourite, indexPath: cell.indexPath, userInfo: cell.userInfo)
        } else if case btnShare = sender {
            cell.delegate?.zoneCollectionViewCell(cell, didTapOnView: sender, type: .Share, indexPath: cell.indexPath, userInfo: cell.userInfo)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var titleFrame = self.bounds
        titleFrame.size.height = 30
        titleFrame.offsetInPlace(dx: 10, dy: 0)
        titleFrame.size.width -= 5
        titleLabel.frame = titleFrame

        btnFavourites.frame = CGRectMake(ButtonOffset, self.bounds.maxY - ButtonHeight - ButtonOffset, MaxButtonWidth, ButtonHeight)
        btnShare.frame = CGRectMake(self.bounds.midX - MaxButtonWidth/2.0, self.bounds.maxY - ButtonHeight - ButtonOffset, MaxButtonWidth, ButtonHeight)

        distanceContainerView.frame = CGRectMake(self.bounds.maxX - MaxButtonWidth, self.bounds.minY, MaxButtonWidth, self.bounds.height)

    }


}

class ZoneRightContentView: UIView {

    var textView: UITextView!
    weak var cell: ZoneItemCollectionViewCell!

    init() {
        fatalError("not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.redColor()
        textView = UITextView()
        textView.text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        textView.editable = false
        //        textView.userInteractionEnabled = false
        addSubview(textView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        textView.frame = CGRectInset(self.bounds, 10, 10)
    }
}



class RandomColorView: UIView {

    init() {
        fatalError("not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.randomColor()
    }
}

public extension UIColor {

    class func randomColor() -> UIColor {
        func random() -> CGFloat {
            return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        }

        return UIColor(red: random(), green: random(), blue: random(), alpha: 1)
    }
}
