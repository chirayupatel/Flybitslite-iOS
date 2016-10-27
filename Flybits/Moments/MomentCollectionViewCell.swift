//
//  MomentCollectionViewCell.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-18.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

class MomentCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = AppConstants.UI.MomentPlaceholderImage()
    }
    
    func updateImage(_ image:Image?) -> Operation? {
        guard let image = image else {
            self.imageView.image = AppConstants.UI.MomentPlaceholderImage()
            return nil
        }
        
        return BlockOperation() { [weak self] in
            guard let tempSelf = self else { return }
            
            let size = image.smallestBestFittingSizeForSize(viewSize: tempSelf.imageView.frame.size, locale: nil)
            _ = ImageRequest.download(image, nil, size, completion: { [weak self] (image, error) in
                OperationQueue.main.addOperation {
                    if let downloadedImage = image  {
                        self?.imageView.image = downloadedImage
                    } else {
                        self?.imageView.image = AppConstants.UI.MomentPlaceholderImage()
                    }
                }
            }).execute()
        }
    }
}
