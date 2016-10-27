//
//  BarButtonItem.swift
//  FlybitsUI
//
//  Created by Archu on 2016-02-26.
//  Copyright © 2016 flybits. All rights reserved.
//

import UIKit

/* Adds closure instead of delegates for callback on UIBarButtonItem */
class BarButtonItem : UIBarButtonItem {
    var callback: ((_ bar:BarButtonItem)-> Void)?
    
    init(title:String, callback: @escaping (_ bar:BarButtonItem)-> Void) {
        super.init()
        self.title = title
        self.style = .plain
        self.target = self
        self.action = #selector(BarButtonItem.backbuttontapped(_:))
        self.callback = callback
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func backbuttontapped(_ sender: AnyObject) {
        callback?(self)
    }
}


