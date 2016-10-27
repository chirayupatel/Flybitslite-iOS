//
//  ZoneCollectionViewCell.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-13.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

protocol ZoneCollectionViewCellDelegate : class {
    func zoneCollectionViewCellDidSelect(_ cell:ZoneCollectionViewCell, indexPath:IndexPath, userInfo:AnyObject?)
    func zoneCollectionViewCell(_ cell:ZoneCollectionViewCell, didTapOnView:UIView, type:ZoneCollectionViewCell.ButtonType, indexPath:IndexPath, userInfo:AnyObject?)
}

private let RightSideHasCornerRadius = false

class ZoneCollectionViewCell: UICollectionViewCell {
    
    enum ButtonType {
        case none
        case favourite
        case share
        case distance
    }

    enum Page : Int {
        case zoneImage
        case description
    }

    var zoneObject: Zone!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnFavourite: UIButton!

    @IBOutlet weak var lblDistance: UILabel!
    
    @IBOutlet weak var containerViewZoneInfo: UIView!
    @IBOutlet weak var imgZoneView: UIImageView!
    
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak fileprivate var scrollView: UIScrollView!
    @IBOutlet weak fileprivate var scrollContentView: UIView!

    @IBOutlet weak var distanceInfoContainerView: UIView!
    //contains image, names, distance
    @IBOutlet weak var leftContentContainerView: UIView!
    @IBOutlet weak var rightContentContainerView: UIView!

    fileprivate let maskLeftContentLayer = CAShapeLayer()
    fileprivate let maskRightContentLayer = CAShapeLayer()

    fileprivate lazy var context = CIContext()

    fileprivate var pageNumber:Page = .zoneImage {
        didSet {
            let page = CGFloat (pageNumber.rawValue) * scrollView.bounds.width
            scrollView.scrollRectToVisible(CGRect(x: page, y: scrollView.bounds.origin.y, width: scrollView.bounds.size.width, height: scrollView.bounds.height), animated: false)
        }
    }

    fileprivate lazy var imgProcessingQueue: OperationQueue =  {
        let oprn = OperationQueue()
        oprn.name = "com.flybitslite.zoneimageprocessing"
        oprn.qualityOfService = QualityOfService.userInitiated
        return oprn
        }()


    var favourited:Bool = false {
        didSet {
            if btnFavourite != nil {
                btnFavourite.setImage(UIImage(named: favourited ? "ic_favorite_star_w" : "ic_favorite_star_outline_w"), for: UIControlState())
            }
        }
    }

    weak var delegate: ZoneCollectionViewCellDelegate?
    var indexPath: IndexPath!
    weak var userInfo: AnyObject?

    func page() -> Page {
        return pageNumber
    }

    func setPage(_ page:Page) {
        pageNumber = page
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        scrollView.scrollsToTop = false
        let fillColor = UIColor.black.cgColor
        maskLeftContentLayer.fillColor = fillColor
        leftContentContainerView.layer.mask = maskLeftContentLayer

        maskRightContentLayer.fillColor = fillColor
        rightContentContainerView.layer.mask = maskRightContentLayer

        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(ZoneCollectionViewCell.tapGestureActivated(_:)))
        leftContentContainerView.addGestureRecognizer(tapGesture1)
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(ZoneCollectionViewCell.distanceInfoTapGestureActivated(_:)))
        distanceInfoContainerView?.addGestureRecognizer(tapGesture2)

        let createLayer: (_ bounds: CGRect) -> CALayer = { bounds in
            let layer = CALayer()
            layer.name = "blurredView"
            layer.frame = bounds
            layer.backgroundColor = UIColor.white.cgColor
            layer.masksToBounds = true
            layer.contentsGravity = kCAGravityResizeAspectFill
            layer.opacity = 0.6
            return layer
        }
        
        let bottomZoneInfoLayer = createLayer(containerViewZoneInfo.bounds)
        containerViewZoneInfo.layer.insertSublayer(bottomZoneInfoLayer, at: 0)

        let rightContentBackgroundLayer = createLayer(rightContentContainerView.bounds)
        rightContentContainerView.layer.insertSublayer(rightContentBackgroundLayer, at: 0)
    }
    
    func setup(_ zone: Zone, index: IndexPath, zoneDistance: String, locale: Locale?) {
        self.zoneObject = zone
        self.indexPath = index
        self.userInfo = zone
        self.favourited = zone.favourited
        
        self.titleLabel.text = zone.name.localizedValue(locale as NSLocale?, tempDefault: "")
        self.txtDescription.text = zone.zoneDescription.localizedValue(locale as NSLocale?, tempDefault: NSLocalizedString("ZONECELL_VIEW_EMPTY_DESCRIPTION", comment: ""))
        self.setNumOfFavourite(zone.favouriteCount)
        self.setPage(type(of: self).Page.zoneImage)
        self.lblDistance?.text = zoneDistance
        
        do {
            let color = (try? UIColor.rgba(zone.color)) ?? UIColor.darkGray
            self.setImage(UIImage.image(color, size: CGSize(width: 1, height: 1)))
        }
    }

    func setImage(_ image: UIImage?) {

        let transition = CATransition()
        transition.type = kCATransitionFade
        transition.duration = 0.1
        imgZoneView.layer.add(transition, forKey: "fade")

        imgZoneView.image = image
        containerViewZoneInfo.sublayerWithName("blurredView")?.contents = nil
        rightContentContainerView.sublayerWithName("blurredView")?.contents = nil

        guard let img = image else { return }

        imgProcessingQueue.addOperation { [weak self] in

            guard let tempSelf = self, let input = CIImage(image: img) else { return }

            let transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            let inputImg = input.applying(transform)

            var blurredImage = CIFilter(name: "CIVibrance", withInputParameters: [kCIInputImageKey:inputImg, "inputAmount":1])!.outputImage!
            blurredImage = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius":4, kCIInputImageKey:blurredImage])!.outputImage!

            let newImg = tempSelf.context.createCGImage(blurredImage, from: inputImg.extent)

            OperationQueue.main.addOperation { [weak self] in
                guard let tempSelf = self else { return }

                let transition = CATransition()
                transition.type = kCATransitionFade
                transition.duration = 0.1
                let containerLayer = tempSelf.containerViewZoneInfo.sublayerWithName("blurredView")
                let contentLayer = tempSelf.rightContentContainerView.sublayerWithName("blurredView")
                
                containerLayer?.add(transition, forKey: "fade")
                contentLayer?.add(transition, forKey: "fade")

                containerLayer?.contents = newImg
                contentLayer?.contents = newImg
            }
        }
    }

    func tapGestureActivated(_ sender: UITapGestureRecognizer) {
        delegate?.zoneCollectionViewCellDidSelect(self, indexPath:indexPath, userInfo:userInfo)
    }
    
    func distanceInfoTapGestureActivated(_ sender: UITapGestureRecognizer) {
        delegate?.zoneCollectionViewCell(self, didTapOnView: sender.view!, type: .distance, indexPath: indexPath, userInfo: userInfo)
    }
    
    func setNumOfFavourite(_ numOfFav:Int) {
        btnFavourite.setTitle("\(numOfFav)", for: UIControlState())
    }

    @IBAction func zoneFavouriteButtonTapped(_ sender: UIButton) {
        delegate?.zoneCollectionViewCell(self, didTapOnView: sender, type: .favourite, indexPath: indexPath, userInfo: userInfo)
    }
    
    @IBAction func zoneShareButtonTapped(_ sender: UIButton) {
        delegate?.zoneCollectionViewCell(self, didTapOnView: sender, type: .share, indexPath: indexPath, userInfo: userInfo)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imgProcessingQueue.cancelAllOperations()
        imgZoneView.image = nil
        
        self.rightContentContainerView.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.disableActions()

        scrollView.contentSize = scrollContentView.frame.size

        let cornerRadius: CGFloat = 6.0
        let size = CGSize(width: cornerRadius, height: cornerRadius)
        maskLeftContentLayer.frame = leftContentContainerView.bounds
        maskLeftContentLayer.path = UIBezierPath(roundedRect: maskLeftContentLayer.frame, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: size).cgPath
        maskRightContentLayer.frame = rightContentContainerView.bounds
        if RightSideHasCornerRadius {
            maskRightContentLayer.path = UIBezierPath(roundedRect: maskRightContentLayer.frame, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: size).cgPath
        } else {
            maskRightContentLayer.path = UIBezierPath(rect: maskRightContentLayer.frame).cgPath
        }

        containerViewZoneInfo.sublayerWithName("blurredView")?.frame = containerViewZoneInfo.bounds
        rightContentContainerView.sublayerWithName("blurredView")?.frame = rightContentContainerView.bounds

        CATransaction.commit()
    }
}


extension ZoneCollectionViewCell : UIScrollViewDelegate {
    // cuz we got paging enabled, this is enough!
    func  scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.rightContentContainerView.isHidden = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let page = ZoneCollectionViewCell.Page(rawValue: Int(scrollView.contentOffset.x / scrollView.bounds.width)) {
            setPage(page)
            if page == .zoneImage {
                self.rightContentContainerView.isHidden = true
            }
        }
    }
}


extension LocalizedObject {
    func localizedValue(_ locale: NSLocale?, tempDefault: T) -> T {
        if let locale = locale {
            do {
                return try self.value(for: locale as Locale) ??  self.defaultValue ?? tempDefault
            } catch {
                
            }
        }
        return self.defaultValue ?? tempDefault
    }
}
