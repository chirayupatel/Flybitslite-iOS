//
// CalendarEventMomentDetailViewController.swift
// Copyright (c) :YEAR: Flybits (http://flybits.com)
//
// Permission to use this codebase and all related and dependent interfaces
// are granted as bound by the licensing agreement between Flybits and
// :COMPANY_NAME: effective :EFFECTIVE_DATE:.
//
// Flybits Framework version :VERSION:
// Built: :BUILD_DATE:
//

import UIKit

class CalendarEventMomentDetailViewController: UIViewController {
    @IBOutlet weak var detailLabel: UITextView!

    var event: CalendarEvent?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.detailLabel.textStorage.setAttributedString(NSAttributedString(string: ""))
        if let cellInfo = event {
            
            let deviceLocale: String
            if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
                deviceLocale = deviceLocaleIdentifier.lowercased()
            } else {
                deviceLocale = "en".lowercased()
            }
            
            let paragraph = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraph.alignment = NSTextAlignment.center
            
            self.addTopImage(UIImage(named: "ic_logo")!, replace: false)
            do {
                if let eventName = try event?.title?.value(for: Locale(identifier: deviceLocale)) {
                    self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                    self.detailLabel.textStorage.append(NSAttributedString(string: eventName.XMLEntitiesDecode(), attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14), NSParagraphStyleAttributeName: paragraph]))
                }
                if let eventLocation = event?.location {
                    self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                    self.detailLabel.textStorage.append(NSAttributedString(string: eventLocation.name!.value!.XMLEntitiesDecode(), attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.darkGray, NSParagraphStyleAttributeName: paragraph]))
                }
                if let eventPhoneNumber = event?.owner?.phoneNumber {
                    let phoneNumber = eventPhoneNumber.XMLEntitiesDecode()
                    self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                    self.detailLabel.textStorage.append(NSAttributedString(string: phoneNumber, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13), NSParagraphStyleAttributeName: paragraph]))
                }
                if let eventDescription = try event?.eventDescription?.value(for: Locale(identifier: deviceLocale)) {
                    self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                    self.detailLabel.textStorage.append(NSAttributedString(string: eventDescription.XMLEntitiesDecode(), attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 13), NSParagraphStyleAttributeName: paragraph]))
                }
                if let eventStartTime = event?.startTime, let eventEndTime = event?.endTime {
                    let dateString = getDateString(startTimestamp: eventStartTime, endTimestamp: eventEndTime)
                    self.detailLabel.textStorage.append(NSAttributedString(string: "\n\n"))
                    self.detailLabel.textStorage.append(NSAttributedString(string: dateString, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.darkGray, NSParagraphStyleAttributeName: paragraph]))
                }
            } catch {
                print("oops")
            }
            
            guard cellInfo.colour != "" else {
                return
            }
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
    
    func getDateString(startTimestamp: Double, endTimestamp: Double) -> String {
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

        if let firstAttachment = self.detailLabel.textStorage.lite_attachments().first, replace {
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
