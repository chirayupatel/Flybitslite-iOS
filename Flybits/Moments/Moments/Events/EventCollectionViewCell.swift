//
//  EventCollectionViewCell.swift
//  Flybits
//
//  Created by Terry Latanville on 2015-10-30.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

protocol EventCollectionViewCellDelegate : class {
    func collectionView(_ collectionViewCell: UICollectionViewCell, shareButtonTappedAtIndex: IndexPath, shareView: UIView)
}

class EventCollectionViewCell: UICollectionViewCell {
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

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventDescriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var shareView: UIView!
    var indexPath: IndexPath!
    weak var delegate: EventCollectionViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EventCollectionViewCell.shareButtonTapped(_:)))
        shareView.addGestureRecognizer(tapGesture)
    }

    func shareButtonTapped(_ sender: UITapGestureRecognizer) {
        delegate?.collectionView(self, shareButtonTappedAtIndex: indexPath, shareView: shareView)
    }

    override func prepareForReuse() {
        eventImageView.image = UIImage(named: "ic_logo")
        eventTitleLabel.text = ""
        dateLabel.text = ""
        setDescriptionText("")
    }

    func setDescriptionText(_ text: String) {
        eventDescriptionLabel.text = text
    }

    func setDateText(startTimestamp: Int, endTimestamp: Int) {
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTimestamp))
        if endTimestamp - startTimestamp >= 86400 { // 1 day
            dateLabel.text = " \(DateFormat.dateAndTime.string(from: startDate)) - \(DateFormat.dateAndTime.string(from: endDate)) "
        } else {
            dateLabel.text = " \(DateFormat.dateAndTime.string(from: startDate)) - \(DateFormat.time.string(from: endDate)) "
        }
    }

    func setImage(_ img: UIImage) {
        eventImageView.layer.cornerRadius = eventImageView.frame.size.width / 2
        eventImageView.layer.masksToBounds = true

        UIView.transition(with: eventImageView, duration: 0.2, options: .transitionCrossDissolve, animations: { () -> Void in
            self.eventImageView.image = img
            self.eventImageView.setNeedsDisplay()
        }, completion: nil)
    }

}
