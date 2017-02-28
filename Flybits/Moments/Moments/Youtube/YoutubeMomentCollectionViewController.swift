//
//  YoutubeMomentCollectionViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-18.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private let reuseIdentifierCellList = "CellList"

class YoutubeMomentCollectionViewController: UICollectionViewController, MomentModule, YoutubeVideoCollectionViewCellDelegate {

    open var moment:Moment!
    fileprivate var data: YoutubeMomentData?
    fileprivate var imageQ: OperationQueue = OperationQueue()
    weak var loadingView: UIView?

    fileprivate var listLayout: UICollectionViewLayout {
        let layout = YoutubeVideoListCollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.itemSize = CGSize(width: self.collectionView!.frame.width, height: 80)
        layout.minimumLineSpacing = 10
        return layout
    }

    public required init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder, moment:Moment) {
        self.moment = moment
        super.init(coder: aDecoder)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        collectionView?.setCollectionViewLayout(self.listLayout, animated: true)

        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.black
        loadingView = dimmedLoadingView
        self.title = moment.name.value
        // Do any additional setup after loading the view.
        _ = moment.validate({ (success, error) in
            if success {
                self.loadData(dimmedLoadingView)
            } else {
                OperationQueue.main.addOperation {
                    dimmedLoadingView.removeFromSuperview()
                    let alert = UIAlertController.cancellableAlertConroller("Validation Failed", message:error?.localizedDescription, handler: nil)
                    self.present(alert, animated: true, completion: nil)

                }
                print(error as Any)
            }
        })
    }

    open override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.collectionView?.reloadData()
    }

    func loadData(_ loadingView:UIView?) {
        
        _ = YoutubeMomentRequest.getVideos(moment: self.moment, allLocales: true) { (data, error) -> Void in
            defer {
                OperationQueue.main.addOperation {
                    loadingView?.removeFromSuperview()
                }
            }

            OperationQueue.main.addOperation {
                if let webmomentData = data {
                    self.data = webmomentData
                    self.collectionView?.reloadData()
                } else {
                    self.data?.items.removeAll()
                    self.collectionView?.reloadData()
                    let alert = UIAlertController.cancellableAlertConroller(nil, message: "There are no videos available.", handler: nil)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }.execute()
    }

    open func initialize(_ moment:Moment) {
        self.moment = moment
    }

    open func load(_ moment:Moment, info:AnyObject?) {
        load(moment, info: info, completion: nil)
    }

    open func load(_ moment:Moment, info:AnyObject?, completion:((_ data:Data?, _ error:NSError?, _ otherInfo:NSDictionary?)->Void)?) {
        self.moment = moment
    }

    open func unload(_ moment:Moment) {
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open override func viewDidLayoutSubviews() {
        loadingView?.frame = self.view.bounds
        super.viewDidLayoutSubviews()
    }

    // MARK: UICollectionViewDataSource

    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = data?.items.count , count > 0 {
            return count
        }
        return 1
    }
    fileprivate static let dateFormatter: DateFormatter = {
        // 2015-07-16T21:30:31+0000
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sss'Z'"
        
        return dateFormatter
    }()
    
    fileprivate static let dateStringFormatter: DateFormatter = {
        // 2015-07-16T21:30:31+0000
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        return dateFormatter
    }()


    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard data?.items.count > 0 else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierCellList, for: indexPath) as! YoutubeVideoCollectionViewCell
        cell.delegate = self

        if let item = data?.items[(indexPath as NSIndexPath).item] {
            cell.titleLabel.text = item.videoTitle?.Lite_HTMLDecodedString
            if let dateString = item.publishedAt,
                let date = YoutubeMomentCollectionViewController.dateFormatter.date(from: dateString),
                let channel = item.channelTitle?.Lite_HTMLDecodedString {
                    
                cell.subtitleLabel.text = "\(channel) | \(YoutubeMomentCollectionViewController.dateStringFormatter.string(from: date))"
            } else {
                cell.subtitleLabel.text = item.channelTitle?.Lite_HTMLDecodedString
            }
            
            imageQ.addOperation(cell.setImage(item.thumbnail.url))
        }

        // Configure the cell
        return cell
    }

    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)

        // empty cell is tapped
        guard data?.items.count > 0 else {
            return
        }

        if let videoItem = data?.items[(indexPath as NSIndexPath).item] {
            openVideoDetailPage(videoItem)
        }
    }

    func openVideoDetailPage(_ item:YoutubeMomentData.VideoItem) {
        if let videoID = item.videoID {
            let vc = YoutubeVideoPlayerViewController()
            vc.videoID = videoID
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let alert = UIAlertController.cancellableAlertConroller("Video is not available", message: nil, handler: nil)
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    //MARK -- Delegates
    func collectionViewCellDidTap(_ cell: YoutubeVideoCollectionViewCell) {
        let indexPath = self.collectionView?.indexPath(for: cell)
        if let indexPath = indexPath, let videoItem = data?.items[(indexPath as NSIndexPath).item] {
            openVideoDetailPage(videoItem)
        }
    }


    //MARK -- Models
    open class YoutubeMomentData : NSObject, ResponseObjectSerializable {
        open var items: [VideoItem] = []

        public required init?(response: HTTPURLResponse, representation: AnyObject) {
            super.init()
            if let dictionary = representation as? NSDictionary {
                if commonInit(dictionary) == false {
                    return nil
                }
            }
        }

        init?(dictionary:NSDictionary) {
            super.init()
            if commonInit(dictionary) == false {
                return nil
            }
        }
        
        fileprivate func commonInit(_ dictionary:NSDictionary) -> Bool {
            if let dict = dictionary as? [String:NSDictionary] , dict.first?.1["id"] is Int {
                for (locale, itemDict) in dict {
                    if let videosDict = itemDict.value(forKey: "youtubeVideos") as? [NSDictionary] {
                        for tempDict in videosDict {
                            if let item = VideoItem(dictionary: tempDict, localizationCode: locale) {
                                items.append(item)
                            }
                        }
                    }
                }
            } else {
                if let videosDict = dictionary.value(forKey: "youtubeVideos") as? [NSDictionary] {
                    for tempDict in videosDict {
                        if let item = VideoItem(dictionary: tempDict, localizationCode: "") {
                            items.append(item)
                        }
                    }
                }
            }
            return true
        }

        open class VideoItem {
            open var localizationCode: String!
            open var videoUrl: String?
            open var videoID: String?
            open var embeddedUrl: String?
            open var channelTitle: String?
            open var publishedAt: String?
            open var videoDescription: String?
            open var videoTitle: String?
            open var thumbnail: Thumbnail!

            init?(dictionary:NSDictionary, localizationCode:String) {

                let tempDict = dictionary
                self.localizationCode = localizationCode.Lite_HTMLDecodedString
                videoUrl = tempDict.htmlDecodedString("videoUrl")
                embeddedUrl = tempDict.htmlDecodedString("embeddedUrl")

                if let videoDict = tempDict.value(forKey: "video") as? NSDictionary {
                    videoID = videoDict.htmlDecodedString("id")
                    if let snippet = videoDict.value(forKeyPath: "snippet") as? NSDictionary {
                        channelTitle = snippet.htmlDecodedString("channelTitle")
                        videoDescription = snippet.htmlDecodedString("description")
                        videoTitle = snippet.htmlDecodedString("title")

                        if let thumbnails = snippet["thumbnails"] as? [String:AnyObject] {
                            thumbnail = Thumbnail(dictionary: thumbnails["default"] as! NSDictionary)
                        }
                        publishedAt = snippet.htmlDecodedString("publishedAt")
                    }
                }
            }
        }

        public struct Thumbnail {
            var height: Int
            var width: Int
            var url: String

            init(dictionary:NSDictionary) {
                height = dictionary.numForKey("height")?.intValue ?? 0
                width = dictionary.numForKey("width")?.intValue ?? 0
                url = dictionary.value(forKey: "url") as? String ?? ""
            }
        }
    }
}

enum YoutubeMomentRequest : Requestable {
    
    // --- cases
    case getVideos(moment: Moment, allLocales: Bool, completion: (_ data: YoutubeMomentCollectionViewController.YoutubeMomentData?, _ error: NSError?) -> Void)
    case getVideo(moment: Moment, videoID: Int, completion: (_ data: YoutubeMomentCollectionViewController.YoutubeMomentData?, _ error: NSError?) -> Void)
    
    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }
    
    var baseURI: String {
        switch self {
        case let .getVideos(moment, allLocales, _):
            return moment.launchURL + "/youtubebits" + (allLocales ? "?alllocales=true" : "")
        case let .getVideo(moment, videoID, _):
            return moment.launchURL + "/youtubebits/\(videoID)"
        }
    }
    
    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getVideos(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: YoutubeMomentCollectionViewController.YoutubeMomentData?, error) -> Void in
                completion(data, error)
            }
        case .getVideo(_, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: YoutubeMomentCollectionViewController.YoutubeMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}
