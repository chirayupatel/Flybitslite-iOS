//
//  SingleGalleryView.swift
//  Flybits
//
//  Created by Archu on 2016-02-16.
//  Copyright © 2016 Flybits. All rights reserved.
//

import UIKit

class SingleGalleryView: UIScrollView, UIScrollViewDelegate {
    
    var image: UIImage? {
        didSet {
            imageView.image = image ?? UIImage(named: "ic_image_loading_placeholder")
            updateSizes()
            setMaxMinZoomScalesForCurrentBounds()
        }
    }
    fileprivate var imageView: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let boundsSize = self.bounds.size;
        var frameToCenter = imageView.frame;
        
        // Horizontally
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2.0)
        } else {
            frameToCenter.origin.x = 0;
        }
        
        // Vertically
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2.0)
        } else {
            frameToCenter.origin.y = 0;
        }
        
        // Center
        if (!imageView.frame.equalTo(frameToCenter)) {
            imageView.frame = frameToCenter;
        }
    }
    
    fileprivate func updateSizes() {
        let scrollView = self
        scrollView.zoomScale = 1
        scrollView.maximumZoomScale = 1
        scrollView.minimumZoomScale = 1
        scrollView.contentSize = CGSize.zero
        
        if let image = image {
            let photoImageViewFrame: CGRect = CGRect(origin: CGPoint.zero, size: image.size)
            imageView.frame = photoImageViewFrame
            scrollView.contentSize = photoImageViewFrame.size
        }
    }
    
    fileprivate func setMaxMinZoomScalesForCurrentBounds() {
        let scrollView = self
        // Reset
        scrollView.zoomScale = 1;
        scrollView.maximumZoomScale = 1;
        scrollView.minimumZoomScale = 1;
        
        // Sizes
        let boundsSize = scrollView.bounds.size;
        let imageSize = imageView.frame.size;
        
        // Calculate Min
        let xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        let yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        var minScale = min(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
        
        // If image is smaller than the screen then ensure we show it at
        // min scale of 1
        if (xScale > 1 && yScale > 1) {
            minScale = 1.0;
        }
        
        // Calculate Max
        let maxScale = 2.0 / UIScreen.main.scale // Allow double scale
        
        // Set
        scrollView.maximumZoomScale = maxScale;
        scrollView.minimumZoomScale = minScale;
        scrollView.zoomScale = minScale;
        
        // Reset position
        imageView.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
        self.setNeedsLayout()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let scrollView = self
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
        imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
        y: scrollView.contentSize.height * 0.5 + offsetY);
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    fileprivate func commonInit() {
        self.backgroundColor = UIColor.white
        self.delegate = self
        addSubview(imageView)
        imageView.backgroundColor = UIColor.white
        setMaxMinZoomScalesForCurrentBounds()
        
        let dblTap = UITapGestureRecognizer(target: self, action: #selector(SingleGalleryView.doubleTap(_:)))
        dblTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(dblTap)
    }
    
    func doubleTap(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            if self.zoomScale != self.maximumZoomScale {
                self.zoomScale = self.maximumZoomScale
            } else {
                self.zoomScale = self.minimumZoomScale
            }
        }) 
    }
}
