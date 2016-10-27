//
//  EventDetailViewController.swift
//  Flybits
//
//  Created by Archuthan Vijayaratnam on 1/12/16.
//  Copyright © 2016 Flybits. All rights reserved.
//

import UIKit

class EventDetailViewController: UIViewController {
    @IBOutlet weak var detailLabel: UITextView!

    var event: Event?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.detailLabel.textStorage.setAttributedString(NSAttributedString(string: ""))
        if let cellInfo = event {

            let deviceLocale:String
            if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
                deviceLocale = deviceLocaleIdentifier.lowercased()
            } else {
                deviceLocale = "en".lowercased()
            }

            if let localized = event?.localization(deviceLocale) {

                let paragraph = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                paragraph.alignment = NSTextAlignment.center

                self.addTopImage(UIImage(named: "ic_logo")!, replace: false)
                self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                self.detailLabel.textStorage.append(NSAttributedString(string: localized.eventName.XMLEntitiesDecode(), attributes: [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14), NSParagraphStyleAttributeName : paragraph]))

                self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                self.detailLabel.textStorage.append(NSAttributedString(string: localized.location.XMLEntitiesDecode(), attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.darkGray, NSParagraphStyleAttributeName : paragraph]))
                
                if let phoneNumber = event!.phoneNumber?.XMLEntitiesDecode() {
                    self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                    self.detailLabel.textStorage.append(NSAttributedString(string: phoneNumber, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 13), NSParagraphStyleAttributeName : paragraph]))
                }

                self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                self.detailLabel.textStorage.append(NSAttributedString(string: localized.eventDescription.XMLEntitiesDecode(), attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 13), NSParagraphStyleAttributeName : paragraph]))

                let dateString = getDateString(startTimestamp: event!.startDate, endTimestamp: event!.endDate)
                self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                self.detailLabel.textStorage.append(NSAttributedString(string: dateString, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.darkGray, NSParagraphStyleAttributeName : paragraph]))

            }
            guard cellInfo.imageURL != "" else {
                return
            }
            guard let url = URL(string: cellInfo.imageURL) else {
                return
            }

            OperationQueue().addOperation({ () -> Void in
                guard let data = try? Data(contentsOf: url), let img = UIImage(data: data) else {
                    OperationQueue.main.addOperation {
                        self.addTopImage(UIImage(named: "ic_logo")!, replace: true)
                    }
                    return
                }
                OperationQueue.main.addOperation {
                    self.addTopImage(img, replace: true)
                }
            })
        } else {
            // display empty view
            self.detailLabel.textStorage.setAttributedString(NSAttributedString(string: "Event is not available", attributes: [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14)]))
        }

        // since image is rendered in a
        OperationQueue.main.addOperation { () -> Void in
            UIView.performWithoutAnimation({ () -> Void in
                self.detailLabel.scrollRangeToVisible(NSMakeRange(0, 1))
            })
        }
    }

    func getDateString(startTimestamp: Int, endTimestamp: Int) -> String {
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTimestamp))
        if endTimestamp - startTimestamp >= 86400 { // 1 day
            return " \(DateFormat.dateAndTime.string(from: startDate)) - \(DateFormat.dateAndTime.string(from: endDate)) "
        } else {
            return " \(DateFormat.dateAndTime.string(from: startDate)) - \(DateFormat.time.string(from: endDate)) "
        }
    }

    func attachmentForImage(_ image: UIImage) -> NSTextAttachment {

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.image = image
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.frame.size.height/2.0

        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, UIScreen.main.scale);

        imageView.drawHierarchy(in: imageView.frame, afterScreenUpdates: true)
        let imageShot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        let attachment = NSTextAttachment()
        attachment.image = imageShot
        attachment.bounds = imageView.frame

        return attachment
    }

    func addTopImage(_ image: UIImage, replace: Bool) {
        let attachment = attachmentForImage(image)
        let paragraph = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.alignment = NSTextAlignment.center
        let mutable = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        mutable.addAttributes([NSParagraphStyleAttributeName : paragraph], range: NSMakeRange(0, mutable.length))

        if let firstAttachment = self.detailLabel.textStorage.lite_attachments().first , replace {
            self.detailLabel.textStorage.replaceCharacters(in: firstAttachment.range, with: mutable)
        } else {
            self.detailLabel.textStorage.setAttributedString(mutable)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    struct DateFormat {
        static let dateAndTime: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy HH:mm"

            return formatter
        }()

        static let time: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"

            return formatter
        }()
    }

}

extension NSAttributedString {
    func lite_attachments() -> [(range: NSRange, attachment: NSTextAttachment)] {
        var array = [(range: NSRange, attachment: NSTextAttachment)]()
        self.enumerateAttribute(NSAttachmentAttributeName, in: NSMakeRange(0, self.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (obj, range, finish) -> Void in
            if let attachment = obj as? NSTextAttachment {
                array.append((range: range, attachment: attachment))
            }
        }
        return array
    }
}
