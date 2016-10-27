//
//  EventMomentViewController.swift
//  Flybits
//
//  Created by Terry Latanville on 2015-10-30.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

enum EventMomentRequest: Requestable {
    case performAction(moment: Moment, action: String, completion: (EventMomentData?, NSError?) -> Void)
    
    var requestType: FlybitsRequestType {
        return .custom
    }
    
    var baseURI: String {
        switch self {
        case .performAction(let moment, _,_):
            return moment.launchURL
        }
    }
    
    var method: HTTPMethod {
        return .GET
    }
    
    var encoding: HTTPEncoding {
        return .url
    }

    var headers: [String:String] {
        return ["Accept-Language" : "en"]
    }

    var path: String {
        switch self {
        case .performAction(_, let action, _):
            return action
        }
    }
    
    func execute() -> FlybitsRequest {
        switch self {
        case .performAction(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, eventData: EventMomentData?, error) -> Void in
                completion(eventData, error)
            }
        }
    }
}

class EventMomentViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MomentModule {
    // MARK: - Constants
    struct Constants {
        static let EventBitAction = "EventBits"
        static let HeaderCellReuseIdentifier = "EventListHeaderCellReuseIdentifier"
        static let CellReuseIdentifier = "EventListCellReuseIdentifier"
    }
    // MARK: - Properties
    var moment: Moment!
    var momentData: EventMomentData?
    fileprivate var imageQ = OperationQueue()

    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundPhotoLayer: UIImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    @IBOutlet weak var noEventsLabel: UILabel!

    // MARK: - Lifecycle Functions
    required init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Show loader

        let dimmedLoadingView = LoadingView(frame: view.frame)
        view.addSubview(dimmedLoadingView)

        _ = moment.validate { (success, error) -> Void in
            if success {
                self.loadData(dimmedLoadingView)
            } else {
                let alert = UIAlertController.cancellableAlertConroller("Validation Failed", message: error?.localizedDescription ?? "Unable to validate this moment", handler: nil)
                self.present(alert, animated: true, completion: nil)
                dimmedLoadingView.removeFromSuperview()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        if let flowLayout = self.collectionView!.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.headerReferenceSize = CGSize(width: view.frame.width, height: flowLayout.headerReferenceSize.height)
            flowLayout.itemSize = CGSize(width: view.frame.width, height: flowLayout.itemSize.height)
        }

        super.viewDidLayoutSubviews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? EventDetailViewController , segue.identifier == "display_detail_event" {
            if let item = self.collectionView.indexPathsForSelectedItems?.first {
                vc.event = momentData?.events?[(item as NSIndexPath).row]
            }
        }
    }

    // MARK: - Functions
    func loadData(_ loadingView: LoadingView?) {
        _ = EventMomentRequest.performAction(moment: moment, action: Constants.EventBitAction) { (momentData, error) -> Void in
            OperationQueue.main.addOperation {
                defer {
                    loadingView?.removeFromSuperview()
                }
                guard error == nil else {
                    print("EventMomentViewController.loadData() ERROR: \(error!)")
                    return
                }
                guard let momentData = momentData else {
                    return
                }
                self.momentData = momentData
                self.eventTitleLabel.text = momentData.title ?? ""
                self.eventDescriptionTextView.text = momentData.summary ?? ""
                
                self.noEventsLabel.text = "There are currently no events."
                self.noEventsLabel.isHidden = momentData.events?.count ?? 0 > 0
                self.collectionView?.reloadData()
            }
        }.execute()
    }

    // MARK: - MomentModule Functions
    func initialize(_ moment: Moment) {
        self.moment = moment
    }
    
    func load(_ moment: Moment, info: AnyObject?) {
        load(moment, info: info, completion: nil)
    }
    
    func load(_ moment: Moment, info: AnyObject?, completion: ((_ data: Data?, _ error: NSError?, _ otherInfo: NSDictionary?) -> Void)?) {
        self.moment = moment
        _ = self.moment.validate { (success, error) -> Void in
            guard let completion = completion else {
                return
            }
            guard success else {
                let controller = UIAlertController.cancellableAlertConroller("Unable to load", message: error?.localizedDescription, handler: nil)
                completion(nil, error, ["viewController" : controller, "pushOnNav" : false])
                return
            }
        }
    }
    
    func unload(_ moment: Moment) { /* NOT IMPLEMENTED */ }

    // MARK: - UICollectionViewDataSource Functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return momentData?.events?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CellReuseIdentifier, for: indexPath) as! EventCollectionViewCell

        if let cellInfo = momentData?.events?[(indexPath as NSIndexPath).row] {
            let oprn = CustomOprn {
                guard let url = URL(string: cellInfo.imageURL), let data = try? Data(contentsOf: url), let img = UIImage(data: data) else {
                    OperationQueue.main.addOperation {
                        cell.setImage(UIImage(named: "ic_logo")!)
                    }
                    return
                }
                OperationQueue.main.addOperation {
                    if let cell = collectionView.cellForItem(at: indexPath) as? EventCollectionViewCell {
                        cell.setImage(img)
                    } else {
                        cell.setImage(UIImage(named: "ic_logo")!)
                    }
                }
            }
            imageQ.addOperation(oprn)
            cell.indexPath = indexPath
            cell.eventTitleLabel.text = cellInfo.eventName
            cell.setDescriptionText(cellInfo.summary)
            cell.setDateText(startTimestamp: cellInfo.startDate, endTimestamp: cellInfo.endDate)
            cell.delegate = self
        }

        return cell
    }
}

extension EventMomentViewController : EventCollectionViewCellDelegate {
    func collectionView(_ collectionViewCell: UICollectionViewCell, shareButtonTappedAtIndex indexPath: IndexPath, shareView: UIView) {

        let deviceLocale:String
        if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            deviceLocale = deviceLocaleIdentifier.lowercased()
        } else {
            deviceLocale = "en".lowercased()
        }

        if let event = momentData?.events?[(indexPath as NSIndexPath).row].localization(deviceLocale) {
            let eventShareItem = EventShareItem(text: event.eventName, image: nil)
            eventShareItem.location = event.location
            let vc = UIActivityViewController(activityItems: [eventShareItem], applicationActivities: nil)
            self.present(vc, animated: true, completion: nil)
        } else {

        }

    }
}



class EventShareItem: NSObject, UIActivityItemSource {

    var text: String
    var location: String?
    var image: UIImage?
    init(text:String, image: UIImage?) {
        self.text = text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        if let location = location {
            return "\(text) \n\n\n \(location)"
        } else {
            return text
        }
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return text
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        if let location = location {
            return "\(text) \n\n\n \(location)"
        } else {
            return text
        }
    }
}

