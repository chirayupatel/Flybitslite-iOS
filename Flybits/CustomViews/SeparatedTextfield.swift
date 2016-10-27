//
//  SeparatedTextfieldTableViewCell.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

@IBDesignable
class SeparatedTextfield: UIView {

    static let SeparatorDefaultHeight: CGFloat = 1

    @IBInspectable var title: String?
    @IBInspectable var placeholder: String?
    @IBInspectable var secureTextEntry: Bool = false
    @IBInspectable var themeColor: UIColor = UIColor.black
    @IBInspectable var image: UIImage!
    @IBInspectable var displayImage: Bool = true
    @IBInspectable var displayErrorImage: Bool = true
    @IBInspectable var imageError: UIImage? = UIImage(named: "ic_invalid_password")

    @IBInspectable var separatorVisible: Bool = true {
        didSet {
            if let constraint = constraintSeparatorHeight {
                constraint.constant = separatorVisible ? SeparatedTextfield.SeparatorDefaultHeight : 0
            }
        }
    }

    @IBInspectable var separatorColor: UIColor?

    fileprivate(set) var separatorView: UIView?
    fileprivate(set) var textfield: UITextField!
    fileprivate(set) var imageView: UIImageView!

    fileprivate var constraintSeparatorHeight:NSLayoutConstraint?


    var text: String? {
        get {
            return textfield.text
        }
        set (value) {
            textfield.text = value
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    init(placeholder:String, image:UIImage, themeColor:UIColor, delegate:UITextFieldDelegate?) {
        super.init(frame: CGRect.zero)
        self.placeholder = placeholder
        self.themeColor = themeColor
        self.image = image

        commonInit()
        textfield.delegate = delegate
    }
    override func awakeFromNib() {
        commonInit()
        super.awakeFromNib()
    }

    func commonInit() {
        if textfield == nil {
            textfield = UITextField()
        }
        if imageView == nil {
            imageView = UIImageView(image: image)
        }
        textfield?.removeFromSuperview()
        imageView?.removeFromSuperview()
        addSubview(textfield)
        addSubview(imageView)
        setupAutolayouts()
    }


    fileprivate func setupAutolayouts() {
        textfield.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        textfield.textColor = themeColor
        textfield.tintColor = themeColor
        if let title = title {
            textfield.text = title
        }
        if let placeholder = placeholder {
            textfield.placeholder = placeholder
        }
        textfield.isSecureTextEntry = secureTextEntry

        imageView.contentMode = UIViewContentMode.scaleAspectFit


        let views = ["left":imageView, "textfield":textfield] as [String : Any]

        if displayImage {
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[left(==20)]-[textfield]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[left(==20)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))

            addConstraint(NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: textfield, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))

        } else {
            imageView.image = nil
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textfield]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        }

        if separatorVisible {
            let separator = LineSeparatorView()
            separator.translatesAutoresizingMaskIntoConstraints = false

            if let separatorColor = separatorColor {
                separator.backgroundColor = separatorColor
            } else {
                separator.backgroundColor = themeColor
            }
            addSubview(separator)

            let views = ["separator": separator, "textfield":textfield] as [String : Any]
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[separator]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[textfield]-[separator]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))

            constraintSeparatorHeight = NSLayoutConstraint(item: separator, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: SeparatedTextfield.SeparatorDefaultHeight)

            self.addConstraint(constraintSeparatorHeight!)
            separatorView = separator

        } else {

            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textfield]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        }
    }

    func displayErrorView() {
        guard displayErrorImage else { return }
        if let img = imageError {
            imageView.image = img
        }
    }

    func removeErrorView() {
        imageView.image = image
    }

    override func resignFirstResponder() -> Bool {
        textfield.resignFirstResponder()
        return super.resignFirstResponder()
    }

}
