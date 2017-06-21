//
//  CalendarEventMomentViewController.swift
//  Flybits
//
//  Created by Alex on 5/18/17.
//  Copyright © 2017 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

class CalendarEventMomentViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MomentModule {
    
    // MARK: - Constants
    struct Constants {
        static let EventBitAction = "EventBits"
        static let HeaderCellReuseIdentifier = "EventListHeaderCellReuseIdentifier"
        static let CellReuseIdentifier = "EventListCellReuseIdentifier"
    }
    // MARK: - Properties
    var moment: Moment!
    var jwtToken: String?
    
    var calendarEventsMomentData: [CalendarEvent]?
    var calendarEventsMomentDataPager: Pager?
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
    
    var deviceLocale: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            deviceLocale = deviceLocaleIdentifier.lowercased()
        } else {
            deviceLocale = "en".lowercased()
        }
        
        // Show loader
        let dimmedLoadingView = LoadingView(frame: view.frame)
        view.addSubview(dimmedLoadingView)
        _ = MomentRequest.authorize(momentIdentifier: moment.identifier) { [unowned self] (authorization, error) -> Void in
            OperationQueue.main.addOperation {
                if let authorization = authorization {
                    self.jwtToken = authorization.payload
                    DispatchQueue.main.async {
                        dimmedLoadingView.removeFromSuperview()
                    }
                    self.loadData(dimmedLoadingView)
                } else {
                    let alert = UIAlertController.cancellableAlertConroller("Validation Failed", message: error?.localizedDescription ?? "Unable to validate this moment", handler: nil)
                    self.present(alert, animated: true, completion: nil)
                    dimmedLoadingView.removeFromSuperview()
                }
            }
        }.execute()
    }
    
    func createUser() -> CalendarEventUser {
        var eventUserDictionary: [String: AnyObject] = [:]
        eventUserDictionary["firstName"] = "Alex" as AnyObject
        eventUserDictionary["lastName"] = "Smith" as AnyObject
        eventUserDictionary["email"] = "not_a_real_email_address@flybits.com" as AnyObject
        eventUserDictionary["phoneNumber"] = "(555) 555-5555" as AnyObject
        eventUserDictionary["status"] = "accepted" as AnyObject
        let eventUser = CalendarEventUser(response: HTTPURLResponse.init(), representation: eventUserDictionary as AnyObject)!
        return eventUser
    }
    
    func createLocation() -> CalendarEventLocation {
        var eventLocation: [String: AnyObject] = [:]
        eventLocation["lat"] = 100 as AnyObject
        eventLocation["lng"] = 200 as AnyObject
        eventLocation["localizations"] = ["en": ["name": "My house", "description": "It's a bungalow"]] as NSDictionary
        return CalendarEventLocation(response: HTTPURLResponse.init(), representation: eventLocation as AnyObject)!
    }
    
    func addupdateReadDeleteEvent() {
        guard let jwtToken = jwtToken else {
            print("Error: You must authorize and validate before calling the CalendarEvent APIs")
            return
        }
        
        var representation: [String: AnyObject] = [:]
        representation["startTime"] = Date().timeIntervalSince1970 as AnyObject
        representation["endTime"] = Date().timeIntervalSince1970 + 300 as AnyObject
        let localizationsDict1 = ["en": ["title": "Birthday Party!", "subtitle": "No gifts", "description": "Come hang and swim in the pool"]] as NSDictionary
        representation["localizations"] = localizationsDict1
        representation["isAllDay"] = true as AnyObject
        representation["colour"] = "#0066EE" as AnyObject
        representation["eventType"] = CalendarEventType.publicEvent as AnyObject
        
        let eventUser = try! createUser().toDictionary() as AnyObject
        
        representation["owner"] = eventUser
        representation["invitees"] = [eventUser] as AnyObject
        
        let eventLocation = try! createLocation().toDictionary() as AnyObject
        representation["location"] = try! CalendarEventLocation(response: HTTPURLResponse(), representation: eventLocation)!.toDictionary() as AnyObject
        
        let event = CalendarEvent(response: HTTPURLResponse.init(), representation: representation as AnyObject)
        _ = CalendarEventMomentRequest.addEvent(moment: self.moment!, jwtToken: jwtToken, event: event!) { (calendarEvent1, error1) in
            guard let calendarEvent1 = calendarEvent1, error1 == nil else {
                print(error1!.localizedDescription)
                return
            }
            _ = CalendarEventMomentRequest.getEvent(moment: self.moment!, jwtToken: jwtToken, eventId: calendarEvent1.identifier!) { (calendarEvent2, error2) in
                guard let calendarEvent2 = calendarEvent2, error2 == nil else {
                    print(error2!.localizedDescription)
                    return
                }
                _ = CalendarEventMomentRequest.updateEvent(moment: self.moment!, jwtToken: jwtToken, event: calendarEvent2) { (calendarEvent3, error3) in
                    guard let calendarEvent3 = calendarEvent3, error3 == nil else {
                        print(error3!.localizedDescription)
                        return
                    }
                    _ = CalendarEventMomentRequest.deleteEvent(moment: self.moment!, jwtToken: jwtToken, eventId: calendarEvent3.identifier!) { (error4) in
                        guard error4 == nil else {
                            print(error4!.localizedDescription)
                            return
                        }
                    }.execute()
                }.execute()
            }.execute()
        }.execute()
    }
    
    func addUpdateReadDeleteUser() {
        guard let jwtToken = jwtToken else {
            print("Error: You must authorize and validate before calling the CalendarEvent APIs")
            return
        }
        let user = createUser()
        _ = CalendarEventAttendeeMomentRequest.getAttendees(moment: self.moment!, jwtToken: jwtToken, email: user.email, pager: nil, sortBy: nil, order: nil) { (calendarEventUsers, pager, error) in
            
            guard let calendarEventUsers = calendarEventUsers, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            _ = CalendarEventAttendeeMomentRequest.getAttendee(moment: self.moment!, jwtToken: jwtToken, attendeeId: calendarEventUsers.first!.userId!) { (calendarEventUser, error) in
                guard let calendarEventUser = calendarEventUser, error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                print(calendarEventUser)
                let calendarQuery = CalendarEventQuery(pager: nil, sortBy: nil, order: nil, type: CalendarEventType.publicEvent, startTime: nil, endTime: nil)
                _ = CalendarEventMomentRequest.getEvents(moment: self.moment!, jwtToken: jwtToken, query: calendarQuery) { (calendarEvents, pager, error) in
                    guard let calendarEvents = calendarEvents, error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    _ = CalendarEventAttendeeMomentRequest.getAttendeesInvitedTo(moment: self.moment!, jwtToken: jwtToken, eventId: calendarEvents.first!.identifier!, pager: nil, sortBy: nil, order: nil) { (calendarEventUsers, pager, error) in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        if let calendarEventUsers = calendarEventUsers, calendarEventUsers.count > 0 {
                            // Cool!
                            print(calendarEventUsers)
                        } else {
                            print("No one is invited to this event yet.")
                        }
                    }.execute()
                }.execute()
            }.execute()
        }.execute()
    }
    
    /*
    func addUpdateReadDeleteLocation() {
        guard let jwtToken = jwtToken else {
            print("Error: You must authorize and validate before calling the CalendarEvent APIs")
            return
        }
        _ = CalendarEventLocationMomentRequest.getLocations(moment: self.moment!, jwtToken: jwtToken, name: nil, locale: nil, pager: nil, orderBy: nil, sortOrder: nil) { (calendarEventLocations, pager, error) in
            guard let calendarEventLocations = calendarEventLocations, error == nil else {
                print(error!.localizedDescription)
                return
            }
            let calendarEventLocation = self.createLocation()
            _ = CalendarEventLocationMomentRequest.addLocation(moment: self.moment!, jwtToken: jwtToken, location: calendarEventLocation) { (calendarEventLocation, error) in
                guard let calendarEventLocation = calendarEventLocation, error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                _ = CalendarEventLocationMomentRequest.getLocation(moment: self.moment!, jwtToken: jwtToken, locationId: calendarEventLocation.identifier!) { (calendarEventLocation, error) in
                    guard let calendarEventLocation = calendarEventLocation, error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                    _ = CalendarEventLocationMomentRequest.updateLocation(moment: self.moment!, jwtToken: jwtToken, location: calendarEventLocation) { (calendarEventLocation, error) in
                        guard let calendarEventLocation = calendarEventLocation, error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                        _ = CalendarEventLocationMomentRequest.deleteLocation(moment: self.moment!, jwtToken: jwtToken, locationId: calendarEventLocation.identifier!) { (error) in
                            guard error == nil else {
                                print(error!.localizedDescription)
                                return
                            }
                        }.execute()
                    }.execute()
                }.execute()
            }.execute()
        }.execute()
    }
    */
    
    override func viewDidLayoutSubviews() {
        if let flowLayout = self.collectionView!.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.headerReferenceSize = CGSize(width: view.frame.width, height: flowLayout.headerReferenceSize.height)
            flowLayout.itemSize = CGSize(width: view.frame.width, height: flowLayout.itemSize.height)
        }
        
        super.viewDidLayoutSubviews()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let vc = segue.destination as? CalendarEventMomentDetailViewController, segue.identifier == "display_detail_event" {
            if let item = self.collectionView.indexPathsForSelectedItems?.first {
                vc.event = calendarEventsMomentData?[(item as NSIndexPath).row]
            }
        }
    }
    
    // MARK: - New Calendar Event example usage!
    
    func loadData(_ loadingView: LoadingView?) {
        
        // Populate CalendarQuery to pass to CalendarEventMomentRequest. This is optional and if
        // provided, it can only be passed to `CalendarEventMomentRequest.getEvents(moment:query:completion:)`
        guard let jwtToken = jwtToken else {
            print("Error: You must authorize and validate before calling the CalendarEvent APIs")
            return
        }
        let calendarQuery = CalendarEventQuery(pager: nil, sortBy: nil, order: nil, type: CalendarEventType.publicEvent, startTime: nil, endTime: nil)
        _ = CalendarEventMomentRequest.getEvents(moment: moment!, jwtToken: jwtToken, query: calendarQuery) { [weak self] (calendarEvents, pager, error) in
            OperationQueue.main.addOperation {
                defer {
                    loadingView?.removeFromSuperview()
                }
                guard error == nil else {
                    print("CalendarEventMomentViewController.loadData() ERROR: \(error!)")
                    return
                }
                guard let calendarEvents = calendarEvents, let pager = pager, error == nil else {
                    print("Failed \(error!.description)")
                    return
                }
                self?.calendarEventsMomentData = calendarEvents
                self?.calendarEventsMomentDataPager = pager
                
                DispatchQueue.main.async {
                    self?.noEventsLabel.text = "There are currently no events."
                    self?.noEventsLabel.isHidden = calendarEvents.count > 0
                    self?.collectionView?.reloadData()
                }
            }
        }.execute()
    }
    
    func initialize(_ moment: FlybitsSDK.Moment) {
        self.moment = moment
    }
    
    @objc(loadMoment:info:)
    func load(_ moment: Moment, info: AnyObject?) {
        load(moment, info: info, completion: nil)
    }
    
    @objc(loadMoment:info:withCompletion:)
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
    
    @objc(unloadMoment:)
    public func unload(_ moment: FlybitsSDK.Moment) { /* NOT IMPLEMENTED */ }
    
    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CellReuseIdentifier, for: indexPath) as! EventCollectionViewCell
        
        if let cellInfo = calendarEventsMomentData?[(indexPath as NSIndexPath).row] {
            cell.indexPath = indexPath
            do {
                if let title = try cellInfo.title?.value(for: Locale(identifier: deviceLocale!)) {
                    cell.eventTitleLabel.text = title
                }
                if let description = try cellInfo.eventDescription?.value(for: Locale(identifier: deviceLocale!)) {
                    cell.setDescriptionText(description)
                }
            } catch {
                print(error.localizedDescription)
            }
            if let startTime = cellInfo.startTime, let endTime = cellInfo.endTime {
                cell.setDateText(startTimestamp: Int(startTime), endTimestamp: Int(endTime))
            }
            cell.delegate = self
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarEventsMomentData?.count ?? 0
    }
}

extension CalendarEventMomentViewController: EventCollectionViewCellDelegate {
    func collectionView(_ collectionViewCell: UICollectionViewCell, shareButtonTappedAtIndex indexPath: IndexPath, shareView: UIView) {
        
        let deviceLocale: String
        if let deviceLocaleIdentifier = (Locale.autoupdatingCurrent as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
            deviceLocale = deviceLocaleIdentifier.lowercased()
        } else {
            deviceLocale = "en".lowercased()
        }
        
        if let event = calendarEventsMomentData?[(indexPath as NSIndexPath).row] {
            var title = ""
            do {
                title = try event.title!.value(for: Locale(identifier: deviceLocale))!
            } catch {
                print(error.localizedDescription)
            }
            let eventShareItem = EventShareItem(text: title, image: nil)
            let lo: LocalizedObject<String> = event.location!.name!
            eventShareItem.location = lo.value
            let vc = UIActivityViewController(activityItems: [eventShareItem], applicationActivities: nil)
            self.present(vc, animated: true, completion: nil)
        } else {
            
        }
    }
}
