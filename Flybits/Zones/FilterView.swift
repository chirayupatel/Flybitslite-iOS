//
//  FilterView.swift
//  Flybits
//
//  Created by chu on 2015-08-20.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

struct Selectable<T> {
    let normal: T?
    let selected: T?

    init(normal:T?, selected:T?) {
        self.normal = normal
        self.selected = selected
    }
}

enum SortOrder {
    case ascending
    case descending
}

protocol FilterViewDelegate : class {
    
    func filterView(_ view:FilterView, didSelectItem item:String, index:Int, sortOrder:SortOrder)
    func filterView(_ view:FilterView, didDeselectItem item:String, index:Int, sortOrder:SortOrder)
    func filterViewDidCancel(_ view:FilterView)
}


class FilterView: UIView {
    static let ArrowHeight: CGFloat = 20
    
    weak var delegate : FilterViewDelegate?
    var sort: SortOrder = .ascending
    
    var arrowImage: UIImage? = UIImage(named: "triangle_b")
    
    var items: [String] = [] {
        didSet {
            viewItems.forEach { (b) -> () in
                b.removeFromSuperview()
            }
            viewItems.removeAll()
            for title in items {
                viewItems.append( itemView(title) )
            }
            setupUI()
        }
    }
    
    var selectedItem: (title:String, index:Int)? = nil {
        willSet {
            if let value = selectedItem {
                deselectItem(value.title)
            }
        }
        didSet {
            if let item = selectedItem?.title {
                _ = selectItem(item)
            }
        }
    }
    var itemHeight: CGFloat = 50
    
    var itemTextColor = Selectable<UIColor>(normal:UIColor.white, selected:UIColor.black) {
        didSet {
            for item in viewItems {
                setupSelectionUI(item)
            }
        }
    }
    
    var itemBackgroundColor = Selectable<UIColor>(normal:UIColor.black, selected:UIColor.clear){
        didSet {
            for item in viewItems {
                setupDeselectionUI(item)
            }
        }
    }

    fileprivate var selectedImage = UIImage(named: "ic_check_b")
    
    var ascendingImage = Selectable<UIImage>(normal: nil, selected: nil) {
        didSet {
            ascendingButton.isHidden = true
            ascendingButton.setImage(ascendingImage.normal!, for: UIControlState())
            ascendingButton.setImage(ascendingImage.selected!, for: .selected)
        }
    }
    
    var descendingImage = Selectable<UIImage>(normal: nil, selected: nil) {
        didSet {
            descendingButton.isHidden = true
            descendingButton.setImage(descendingImage.normal!, for: UIControlState())
            descendingButton.setImage(descendingImage.selected!, for: .selected)
        }
    }
    
    var contentBackgroundColor: UIColor? = UIColor.red {
        didSet {
            contentView.backgroundColor = contentBackgroundColor!
        }
    }
    
    var arrowBackgroundView: UIView = UIView()
    
    fileprivate var viewItems: [UIButton] = []
    fileprivate let contentView = UIView()
    
    fileprivate let ascendingButton: UIButton = UIButton()
    fileprivate let descendingButton: UIButton = UIButton()
    fileprivate var arrowView: UIImageView?
    var arrowImageOrigin: CGPoint = CGPoint.zero
    
    
    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
   
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(FilterView.backgroundViewTapped(_:)))
        self.addGestureRecognizer(tap)
    }
    
    fileprivate func viewWithTitle(_ title:String) -> (index:Int, button:UIButton)? {
        for (index, item) in viewItems.enumerated() where item.titleLabel?.text == title {
            return (index, item)
        }
        return nil
    }
    
    fileprivate func selectItem(_ title:String) -> (index:Int, button:UIButton)? {
        if let item = viewWithTitle(title) {
            
            let button = item.button
            setupSelectionUI(button)
            
            button.viewWithTag(10)?.removeFromSuperview()

            let imgView = UIImageView(image: selectedImage)
            button.addSubview(imgView)
            imgView.tag = 10
            imgView.translatesAutoresizingMaskIntoConstraints = false
            imgView.contentMode = UIViewContentMode.scaleAspectFit
            button.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[img(==15)]-20-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["img":imgView]))
            button.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[img(==15)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["img":imgView]))
            button.addConstraint(NSLayoutConstraint(item: imgView, attribute: .centerY, relatedBy: .equal, toItem: button, attribute: .centerY, multiplier: 1, constant: 0))
            return item
        }
        return nil
    }

    fileprivate func deselectItem(_ title:String?) {
        
        if let title = title, let item = viewWithTitle(title) {
            item.button.viewWithTag(10)?.removeFromSuperview()
            setupDeselectionUI(item.button)
        } else {
            for x in viewItems {
                setupDeselectionUI(x)
            }
        }
    }
    
    fileprivate func setupUI() {
        
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = contentBackgroundColor
        addConstraint(NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier:1, constant: 0))
//        addConstraint(NSLayoutConstraint(item: contentView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier:1, constant: 0))

        var previousView: UIView? = nil
        let metrics = ["itemHeight":itemHeight, "iconHeight":40, "iconWidth":40]
        
        for viewItem in viewItems {
            
            viewItem.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(viewItem)
            
            if let previousView = previousView {
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[previous]-[current(==itemHeight)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: ["previous":previousView, "current":viewItem]))
            } else {
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-30-[current(==itemHeight)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: ["current":viewItem]))
            }
            
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[current]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["current":viewItem]))
            previousView = viewItem
        }
        //add sort views
        ascendingButton.setImage(ascendingImage.normal, for: UIControlState())
        ascendingButton.setImage(ascendingImage.selected, for: .selected)
        ascendingButton.translatesAutoresizingMaskIntoConstraints = false
        ascendingButton.addTarget(self, action: #selector(FilterView.itemAscendingSelected(_:)), for: UIControlEvents.touchUpInside)
        contentView.addSubview(ascendingButton)
        
        descendingButton.setImage(descendingImage.normal, for: UIControlState())
        descendingButton.setImage(descendingImage.selected, for: .selected)
        descendingButton.translatesAutoresizingMaskIntoConstraints = false
        descendingButton.addTarget(self, action: #selector(FilterView.itemDescendingSelected(_:)), for: UIControlEvents.touchUpInside)
        contentView.addSubview(descendingButton)
        
        //add sort constraints
        let sortViews = ["ascending":ascendingButton,"descending":descendingButton]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[ascending(==iconWidth)]-20-[descending(==iconWidth)]-20-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: sortViews))
        
        if let previousView = previousView {
            print(previousView)
            let sortViews = ["ascending":ascendingButton,"descending":descendingButton, "previous":previousView]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[previous]-20-[ascending(==iconHeight)]-20-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: sortViews))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[previous]-20-[descending(==iconHeight)]-20-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: sortViews))
        } else {
            assert(false, "Shouldn't come here for zones...")
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[ascending(==iconHeight)]-[descending(==iconHeight)]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: sortViews))
        }
        
        addSubview(arrowBackgroundView)
    }
    
    fileprivate func itemView(_ item:String) -> UIButton {
        let state = UIControlState()
        let btn = UIButton()
        
        btn.setTitle(item, for: state)
        btn.setTitleColor(itemTextColor.normal, for: state)
        btn.setTitleColor(itemTextColor.selected, for: UIControlState.highlighted)
        btn.titleLabel!.font = UIFont(descriptor: btn.titleLabel!.font.fontDescriptor, size: 15)
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20)
        btn.backgroundColor = itemBackgroundColor.normal
        btn.addTarget(self, action: #selector(FilterView.itemSelected(_:)), for: UIControlEvents.touchUpInside)
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 1.0
        btn.layer.cornerRadius = Theme.currentTheme.buttonCornerRadius

        return btn
    }

    fileprivate func setupSelectionUI(_ view: UIButton) {
        view.setTitleColor(itemTextColor.selected, for: UIControlState())
        view.backgroundColor = itemBackgroundColor.selected
    }

    fileprivate func setupDeselectionUI(_ view: UIButton) {
        view.setTitleColor(itemTextColor.normal, for: UIControlState())
        view.backgroundColor = itemBackgroundColor.normal
    }
    
    //MARK: Button touch event handling
    func itemSelected(_ sender: UIButton) {
        
        deselectItem(selectedItem?.title)
        if let item = selectedItem?.title {
            delegate?.filterView(self, didDeselectItem: item, index:selectedItem!.index, sortOrder: sort)
        }
        selectedItem = nil
        
        if let title = sender.titleLabel?.text, let item = selectItem(title) {
            selectedItem = (item.button.titleLabel!.text!, item.index)
            if let selectedItem = selectedItem {
                delegate?.filterView(self, didSelectItem: selectedItem.title, index:selectedItem.index, sortOrder: sort)
            }
        }
    }
    
    func itemAscendingSelected(_ sender: UIButton) {
        sender.isSelected = true
        descendingButton.isSelected = false
        
        sort = .ascending
        if let item = selectedItem {
            delegate?.filterView(self, didSelectItem: item.title, index:item.index, sortOrder: sort)
        }

    }
    
    func itemDescendingSelected(_ sender: UIButton) {
        sender.isSelected = true
        ascendingButton.isSelected = false
        
        sort = .descending
        if let item = selectedItem {
            delegate?.filterView(self, didSelectItem: item.title, index:item.index, sortOrder: sort)
        }
    }
    
    func backgroundViewTapped(_ sender:UITapGestureRecognizer) {
        let point = sender.location(in: contentView)
        if !contentView.frame.contains(point) {
            delegate?.filterViewDidCancel(self)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.arrowView == nil && self.arrowImage != nil {
            self.arrowView = UIImageView(image: self.arrowImage)
            self.arrowView?.contentMode = UIViewContentMode.scaleAspectFit
        }
        
        guard let arrowView = self.arrowView else { return }
        
        arrowBackgroundView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.arrowImage!.size.height)

        if arrowView.superview == nil {
            addSubview(arrowView)
        }
        
        bringSubview(toFront: arrowView)
        
        arrowView.frame = CGRect(origin: CGPoint(x: arrowImageOrigin.x, y: 0), size: self.arrowImage!.size)
    }
}
