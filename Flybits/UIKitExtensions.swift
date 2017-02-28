//
//  UIKitExtensions.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-10.
//  Copyright © 2015 Flybits. All rights reserved.
//

import Foundation
import UIKit


//https://github.com/yeahdongcn/UIColor-Hex-Swift

extension UIColor {
    
    public static func rgba(_ hex: String) throws -> UIColor {
        var advanceBy = 0
        if hex.hasPrefix("#") {
            advanceBy = 1
        }
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        let index   = hex.characters.index(hex.startIndex, offsetBy: advanceBy)
        let hex     = hex.substring(from: index)
        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch (hex.characters.count) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                alpha = CGFloat(hexValue & 0x000F)             / 15.0
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
            default: throw NSError(domain: "Flybits", code: 0, userInfo: [NSLocalizedDescriptionKey : "INVALID_HEX_FORMAT"])
            }
        }
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public extension UIView {
    public func sublayerWithName(_ name:String) -> CALayer? {
        return self.layer.layerWithName(name)
    }
}

public extension CALayer {
    public func layerWithName(_ name:String) -> CALayer? {
        guard let sublayers = sublayers else { return nil }
        for lay in sublayers {
            if lay.name == name {
                return lay
            } else {
                return lay.layerWithName(name)
            }
        }
        return nil
    }
}

public extension UIViewController {

    public func applyBackgroundColorToNavigationBar(_ color:UIColor) {

        let bar = self.navigationController?.navigationBar
        bar?.setBackgroundImage(UIImage.image(UIColor.clear, size: CGSize(width: 1, height: 1)), for: UIBarMetrics.default)
    }

    public func displayErrorMessage(_ message:String) -> MessageBanner! {
        if let bar = self.navigationController?.navigationBar as? ExtendedNavigationBar {
            let banner = MessageBanner.errorMessage(message)
            bar.displayBanner(banner)
            return banner
        }
        return nil
    }
    
    public func displaySuccessMessage(_ message:String) -> MessageBanner! {
        if let bar = self.navigationController?.navigationBar as? ExtendedNavigationBar {
            let banner = MessageBanner.successMessage(message)
            bar.displayBanner(banner)
            return banner
        }
        return nil
    }


    public func removeErrorBanner() {
        if let bar = self.navigationController?.navigationBar as? ExtendedNavigationBar {
            bar.removeBanner()
        }
    }
}

public extension UIImage {

    public class func image(_ color:UIColor, size:CGSize, scale:CGFloat = 1) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale);
//        let context:CGContextRef? = UIGraphicsGetCurrentContext();
        color.setFill()
//        CGContextSetRGBFillColor(context, 1, 1, 1, 0);
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height));
        let img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img ?? UIImage()
    }
    
    public func resize(_ size:CGSize, scale:CGFloat = 1) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale);
        //        let context:CGContextRef? = UIGraphicsGetCurrentContext();
        //        CGContextSetRGBFillColor(context, 1, 1, 1, 0);
        
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img ?? UIImage()
    }
    
    public func resizeWithAspect(_ width: CGFloat?, height: CGFloat?, scale:CGFloat = 1) -> UIImage {
        
        let newSize: CGSize

//        w = (w1*h)/h1
//        h = h1*w/w1
//        
        if let height = height {
            newSize = CGSize(width:(self.size.width * height)/self.size.height , height: height)
        } else if let width = width {
            newSize = CGSize(width: width, height: (width * self.size.height)/self.size.width)
        } else {
            newSize = self.size
        }
//        print(newSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale);
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return img ?? UIImage()
    }

}

//MARK: Views and Layouts
public extension NSLayoutConstraint {

    public class func equal(_ attribute:NSLayoutAttribute, view1:UIView, asView view2:UIView, parentView:UIView? = nil, constant:CGFloat=0) {

        var parent:UIView! = parentView
        if parentView == nil {
            parent = view2
        }

        parent!.addConstraint(NSLayoutConstraint(item: view1, attribute: attribute, relatedBy: NSLayoutRelation.equal, toItem: view2, attribute: attribute, multiplier: 1, constant: constant))
    }

    public class func fillParent(_ view:UIView, parentView:UIView, insets:UIEdgeInsets = UIEdgeInsets.zero) {

        parentView.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: parentView, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: insets.left))

        parentView.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: parentView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: insets.top))

        parentView.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: parentView, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: insets.right))
        parentView.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: parentView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: insets.bottom))

    }

}

extension UIView {
    func addConstraints(_ child: UIView, attributes: NSLayoutAttribute..., relation: NSLayoutRelation = .equal, multiplier: CGFloat = 1, constant: CGFloat = 0) {
        for attr in attributes {
            let layout = NSLayoutConstraint(item: child, attribute: attr, relatedBy: relation, toItem: self, attribute: attr, multiplier: multiplier, constant: constant)
            self.addConstraint(layout)
        }
    }
    
    func addConstraint(_ visual: String, metrics: [String: AnyObject]?, views: [String: AnyObject], options: NSLayoutFormatOptions = NSLayoutFormatOptions(rawValue: 0)) {
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: visual, options: options, metrics: metrics, views: views))
    }
    
    func addConstrains(_ format:String..., views:[String:AnyObject], options:NSLayoutFormatOptions = NSLayoutFormatOptions(rawValue: 0), metrics:[String : AnyObject]? = nil) -> [NSLayoutConstraint] {
        var cons = [NSLayoutConstraint]()
        for f in format {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: f, options: options, metrics: metrics, views: views)
            cons.append(contentsOf: constraints)
        }
        self.addConstraints(cons)
        return cons
    }
    
    func prepareForAutolayout() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func addSubviews(_ views: UIView...) {
        for v in views {
            addSubview(v)
        }
    }

}

public extension UIAlertController {

    public class func cancellableAlertConroller(_ title:String?, message:String?, handler:((UIAlertAction) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        _ = alert.addDefaultDismiss(handler)
        return alert
    }
    
    public class func alertConroller(_ title:String?, message:String?, setup:((UIAlertController) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        setup?(alert)
        return alert
    }

    func addDefaultDismiss(_ handler:((UIAlertAction) -> Void)?) -> UIAlertController {
        self.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: handler))
        return self
    }
}

public extension String {
    func XMLEntitiesDecode() -> String {
        var str = self
        let characters = ["&gt;": ">", "&lt;": "<", "&amp;": "&", "&quot;": "\"", "&apos;": "'", "&#39;": "'"]
        for (key, val) in characters {
            str = str.replacingOccurrences(of: key,
                with:val, options: NSString.CompareOptions.literal, range: nil)
        }
        return str
    }
    
    var fullRange: Range<String.Index> {
        return self.startIndex ..< self.endIndex
    }
    
    func substringRanges(_ string: String, options: NSString.CompareOptions = .caseInsensitive) -> [NSRange] {
        var ranges: [NSRange] = []
        var sb = self
        var startIndexSoFar: Int = 0
        repeat {
            if let range = sb.range(of: string, options: options, range: nil, locale: nil) {
                let end = sb.characters.distance(from: sb.startIndex, to: range.upperBound)
                startIndexSoFar += sb.characters.distance(from: sb.startIndex, to: range.lowerBound)
                ranges.append(NSMakeRange(startIndexSoFar, string.characters.count))
                startIndexSoFar += string.characters.count
                if sb.characters.distance(from: sb.characters.index(sb.startIndex, offsetBy: end), to: sb.endIndex) > 0 {
                    sb = sb.substring(with: sb.characters.index(sb.startIndex, offsetBy: end) ..< sb.endIndex)
                } else {
                    break
                }
            } else {
                break
            }
        } while true
        return ranges
    }
    
    var appLocalizedString: String {
        return NSLocalizedString(self, comment: self)
    }
}

public extension NotificationCenter {

    public func addObserver(_ names: Notification.Name..., usingBlock block: @escaping (Notification) -> Void) -> [NSObjectProtocol] {
        var arr = [NSObjectProtocol]()
        for name in names {
            let item = self.addObserver(forName: name, object: nil, queue: nil, using: block)
            arr.append(item)
        }
        return arr
    }
    
    public func removeObservers(_ observer: AnyObject, names: Notification.Name...) {
        for name in names {
            self.removeObserver(observer, name: name, object: nil)
        }
    }
}



private let htmlEntities = [
    "&quot;" : "\"",
    "&amp;" : "&",
    "&apos;" : "'",
    "&lt;" : "<",
    "&gt;" : ">",
    "&nbsp;" : " ",
    "&iexcl;" : "¡",
    "&cent;" : "¢",
    "&pound;" : "£",
    "&curren;" : "¤",
    "&yen;" : "¥",
    "&brvbar;" : "¦",
    "&sect;" : "§",
    "&uml;" : "¨",
    "&copy;" : "©",
    "&ordf;" : "ª",
    "&laquo;" : "«",
    "&not;" : "¬",
    "&shy;" : "",
    "&reg;" : "®",
    "&macr;" : "¯",
    "&deg;" : "°",
    "&plusmn;" : "±",
    "&sup2;" : "²",
    "&sup3;" : "³",
    "&acute;" : "´",
    "&micro;" : "µ",
    "&para;" : "¶",
    "&middot;" : "·",
    "&cedil;" : "¸",
    "&sup1;" : "¹",
    "&ordm;" : "º",
    "&raquo;" : "»",
    "&frac14;" : "¼",
    "&frac12;" : "½",
    "&frac34;" : "¾",
    "&iquest;" : "¿",
    "&Agrave;" : "À",
    "&Aacute;" : "Á",
    "&Acirc;" : "Â",
    "&Atilde;" : "Ã",
    "&Auml;" : "Ä",
    "&Aring;" : "Å",
    "&AElig;" : "Æ",
    "&Ccedil;" : "Ç",
    "&Egrave;" : "È",
    "&Eacute;" : "É",
    "&Ecirc;" : "",
    "&Euml;" : "Ë",
    "&Igrave;" : "Ì",
    "&Iacute;" : "Í",
    "&Icirc;" : "Î",
    "&Iuml;" : "Ï",
    "&ETH;" : "Ð",
    "&Ntilde;" : "Ñ",
    "&Ograve;" : "Ò",
    "&Oacute;" : "Ó",
    "&Ocirc;" : "Ô",
    "&Otilde;" : "Õ",
    "&Ouml;" : "Ö",
    "&times;" : "×",
    "&Oslash;" : "Ø",
    "&Ugrave;" : "Ù",
    "&Uacute;" : "Ú",
    "&Ucirc;" : "Û",
    "&Uuml;" : "Ü",
    "&Yacute;" : "Ý",
    "&THORN;" : "Þ",
    "&szlig;" : "ß",
    "&agrave;" : "à",
    "&aacute;" : "á",
    "&acirc;" : "â",
    "&atilde;" : "ã",
    "&auml;" : "ä",
    "&aring;" : "å",
    "&aelig;" : "æ",
    "&ccedil;" : "ç",
    "&egrave;" : "è",
    "&eacute;" : "é",
    "&ecirc;" : "ê",
    "&euml;" : "ë",
    "&igrave;" : "ì",
    "&iacute;" : "í",
    "&icirc;" : "î",
    "&iuml;" : "ï",
    "&eth;" : "ð",
    "&ntilde;" : "ñ",
    "&ograve;" : "ò",
    "&oacute;" : "ó",
    "&ocirc;" : "ô",
    "&otilde;" : "õ",
    "&ouml;" : "ö",
    "&divide;" : "÷",
    "&oslash;" : "ø",
    "&ugrave;" : "ù",
    "&uacute;" : "ú",
    "&ucirc;" : "û",
    "&uuml;" : "ü",
    "&yacute;" : "ý",
    "&thorn;" : "þ",
    "&yuml;" : "ÿ",
    "&OElig;" : "Œ",
    "&oelig;" : "œ",
    "&Scaron;" : "Š",
    "&scaron;" : "š",
    "&Yuml;" : "Ÿ",
    "&fnof;" : "ƒ",
    "&circ;" : "ˆ",
    "&tilde;" : "˜",
    "&Alpha;" : "Α",
    "&Beta;" : "Β",
    "&Gamma;" : "Γ",
    "&Delta;" : "Δ",
    "&Epsilon;" : "Ε",
    "&Zeta;" : "Ζ",
    "&Eta;" : "Η",
    "&Theta;" : "Θ",
    "&Iota;" : "Ι",
    "&Kappa;" : "Κ",
    "&Lambda;" : "Λ",
    "&Mu;" : "Μ",
    "&Nu;" : "Ν",
    "&Xi;" : "Ξ",
    "&Omicron;" : "Ο",
    "&Pi;" : "Π",
    "&Rho;" : "Ρ",
    "&Sigma;" : "Σ",
    "&Tau;" : "Τ",
    "&Upsilon;" : "Υ",
    "&Phi;" : "Φ",
    "&Chi;" : "Χ",
    "&Psi;" : "Ψ",
    "&Omega;" : "Ω",
    "&alpha;" : "α",
    "&beta;" : "β",
    "&gamma;" : "γ",
    "&delta;" : "δ",
    "&epsilon;" : "ε",
    "&zeta;" : "ζ",
    "&eta;" : "η",
    "&theta;" : "θ",
    "&iota;" : "ι",
    "&kappa;" : "κ",
    "&lambda;" : "λ",
    "&mu;" : "μ",
    "&nu;" : "ν",
    "&xi;" : "ξ",
    "&omicron;" : "ο",
    "&pi;" : "π",
    "&rho;" : "ρ",
    "&sigmaf;" : "ς",
    "&sigma;" : "σ",
    "&tau;" : "τ",
    "&upsilon;" : "υ",
    "&phi;" : "φ",
    "&chi;" : "χ",
    "&psi;" : "ψ",
    "&omega;" : "ω",
    "&thetasym;" : "ϑ",
    "&upsih;" : "ϒ",
    "&piv;" : "ϖ",
    "&ensp;" : " ",
    "&emsp;" : " ",
    "&thinsp;" : " ",
    "&zwnj;" : "",
    "&zwj;" : "",
    "&lrm;" : "",
    "&rlm;" : "",
    "&ndash;" : "–",
    "&mdash;" : "—",
    "&lsquo;" : "‘",
    "&rsquo;" : "’",
    "&sbquo;" : "‚",
    "&ldquo;" : "“",
    "&rdquo;" : "”",
    "&bdquo;" : "„",
    "&dagger;" : "†",
    "&Dagger;" : "‡",
    "&bull;" : "•",
    "&hellip;" : "…",
    "&permil;" : "‰",
    "&prime;" : "′",
    "&Prime;" : "″",
    "&lsaquo;" : "‹",
    "&rsaquo;" : "›",
    "&oline;" : "‾",
    "&frasl;" : "⁄",
    "&euro;" : "€",
    "&image;" : "ℑ",
    "&weierp;" : "℘",
    "&real;" : "ℜ",
    "&trade;" : "™",
    "&alefsym;" : "ℵ",
    "&larr;" : "←",
    "&uarr;" : "↑",
    "&rarr;" : "→",
    "&darr;" : "↓",
    "&harr;" : "↔",
    "&crarr;" : "↵",
    "&lArr;" : "⇐",
    "&uArr;" : "⇑",
    "&rArr;" : "⇒",
    "&dArr;" : "⇓",
    "&hArr;" : "⇔",
    "&forall;" : "∀",
    "&part;" : "∂",
    "&exist;" : "∃",
    "&empty;" : "∅",
    "&nabla;" : "∇",
    "&isin;" : "∈",
    "&notin;" : "∉",
    "&ni;" : "∋",
    "&prod;" : "∏",
    "&sum;" : "∑",
    "&minus;" : "−",
    "&lowast;" : "∗",
    "&radic;" : "√",
    "&prop;" : "∝",
    "&infin;" : "∞",
    "&ang;" : "∠",
    "&and;" : "∧",
    "&or;" : "∨",
    "&cap;" : "∩",
    "&cup;" : "∪",
    "&int;" : "∫",
    "&there4;" : "∴",
    "&sim;" : "∼",
    "&cong;" : "≅",
    "&asymp;" : "≈",
    "&ne;" : "≠",
    "&equiv;" : "≡",
    "&le;" : "≤",
    "&ge;" : "≥",
    "&sub;" : "⊂",
    "&sup;" : "⊃",
    "&nsub;" : "⊄",
    "&sube;" : "⊆",
    "&supe;" : "⊇",
    "&oplus;" : "⊕",
    "&otimes;" : "⊗",
    "&perp;" : "⊥",
    "&sdot;" : "⋅",
    "&lceil;" : "⌈",
    "&rceil;" : "⌉",
    "&lfloor;" : "⌊",
    "&rfloor;" : "⌋",
    "&lang;" : "〈",
    "&rang;" : "〉",
    "&loz;" : "◊",
    "&spades;" : "♠",
    "&clubs;" : "♣",
    "&hearts;" : "♥",
    "&diams;" : "♦"]

extension String {
    var Lite_HTMLDecodedString: String {
        var decodedString = self
        
        let regex = try! NSRegularExpression(pattern: "&[^;]{2,10};", options: [])
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, self.characters.count)).reversed()
        // Start at the end so we don't have to account for new string length
        for textCheckingResult in results {
            for i in 0 ..< textCheckingResult.numberOfRanges {
                let range = textCheckingResult.rangeAt(i)
                if range.location == NSNotFound {
                    continue
                }
                
                if let range = self.rangeFromNSRange(range) {
                    let htmlEntity = self.substring(with: range)
                    if let value = htmlEntities[htmlEntity] {
                        decodedString.replaceSubrange(range, with: value)
                    } else { // we couldn't decode it using the dictionary, so try decoding it ourselves
                        decodedString.replaceSubrange(range, with: htmlEntity.convertHTMLEntitiesWithHexString())
                    }
                }
            }
        }
        return decodedString
    }
    
    // Converts HTML Entities with hex value ('&#x') to unicode character "&#x2666;" -> "♦"
    // doesn't work with "&hearts;" or any other characters that contains word (amp, quot, apos, ...)
    // Converts the character or return the original character back
    func convertHTMLEntitiesWithHexString() -> String {
        // https://github.com/apple/swift-corelibs-foundation/blob/88424c8c533ce903d10b8be2a8b9f30a4c2011aa/CoreFoundation/Parsing.subproj/CFXMLParser.c
        // CFXMLCreateStringByUnescapingEntities
        
        let str = self
        let newStr = str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var base: UInt32 = 10
        var entity: UInt32 = 0
        
        let amp = "&".unicodeScalars.first!
        let pound = "#".unicodeScalars.first!
        let semi = ";".unicodeScalars.first!
        let hex = "x".unicodeScalars.first!
        let zeroUnicode = "0".unicodeScalars.first!.value
        let nineUnicode = "9".unicodeScalars.first!.value
        let aUnicode = "a".unicodeScalars.first!.value
        let AUnicode = "A".unicodeScalars.first!.value
        let fUnicode = "f".unicodeScalars.first!.value
        let FUnicode = "F".unicodeScalars.first!.value
        
        var chars = newStr.unicodeScalars
        if let f = chars.first , f != amp {
            return str
        }
        chars = chars.dropFirst() // removes &
        if let f = chars.first , f != pound {
            return str
        }
        chars = chars.dropFirst() // removes #
        if let f = chars.first , f == hex {
            base = 16 // since the string has 'x', then its hex
            chars = chars.dropFirst() // removes x
        }
        
        if let l = chars.last , l == semi {
            chars = chars.dropLast() // removes ;
        } else {
            return str
        }
        
        // converts the hex into Int based on character values
        for x in chars {
            let uc = x.value
            if (uc >= zeroUnicode && uc <= nineUnicode) {
                entity = entity * base + (uc - zeroUnicode);
            } else if (uc >= aUnicode && uc <= fUnicode) {
                entity = entity * base + (uc - aUnicode + 10);
            } else if (uc >= AUnicode && uc <= FUnicode) {
                entity = entity * base + (uc - AUnicode + 10);
            }
        }
        
        if(entity >= 0x10000) {
            let first = ((entity - 0x10000) >> 10) + 0xD800
            let second = ((entity - 0x10000) & 0x3ff) + 0xDC00
            let characters:[UniChar] = [UniChar(first), UniChar(second)]
            return CFStringCreateWithCharacters(kCFAllocatorDefault, characters, 2) as String
        } else {
            let characters:[UniChar] = [UniChar(entity)];
            return CFStringCreateWithCharacters(kCFAllocatorDefault, characters, 1) as String
        }
    }
    
    func rangeFromNSRange(_ nsRange: NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advanced(by: nsRange.location)
        let to16 = from16.advanced(by: nsRange.length)
        if let from = String.Index(from16, within: self), let to = String.Index(to16, within: self) {
            return from ..< to
        }
        return nil
    }
    
    func NSRangeFromRange(_ range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        let to = String.UTF16View.Index(range.upperBound, within: utf16view)
        
        
        return NSMakeRange(utf16view.startIndex.distance(to: from), from.distance(to: to))
    }
    
    func lite_localized(_ keys: String...) -> String {
        return String.init(format: NSLocalizedString(self, comment: self), keys)
    }
}
