//
//  ZoneShareItemURLSource.swift
//  Flybits
//
//  Created by chu on 2015-08-24.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class ZoneShareItemURLSource: NSObject, UIActivityItemSource {

    var URL:Foundation.URL
    var subject:String
    var image:UIImage
    
    init(URL:Foundation.URL, subject:String, image:UIImage) {
        self.URL = URL
        self.subject = subject
        self.image = image
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return URL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        return URL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return subject
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return image
    }
}
