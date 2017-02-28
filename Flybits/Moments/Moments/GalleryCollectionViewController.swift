//
//  GalleryCollectionViewController.swift
//  Flybits
//
//  Created by chu on 2015-09-30.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

private let reuseIdentifier = "Cell"
private let reuseIdentifierLoaderCell = "MessageCell"
private let reuseIdentifierSingle = "SingleCell"

open class GalleryCollectionViewController: UICollectionViewController, MomentModule {

    var viewType:String = "Grid" // Grid, Single
    
    open var moment:Moment!
    var data: GalleryMomentData?
    fileprivate var imageQ: OperationQueue = OperationQueue()
    var requestTask : URLSessionDataTask?
    var validateRequest: FlybitsRequest?
    weak var loadingView: UIView?
    fileprivate let imageCache                = NSCache<NSString, UIImage>()

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

        if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            if viewType == "Single" {
                layout.scrollDirection = UICollectionViewScrollDirection.horizontal
                collectionView?.isPagingEnabled = true
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.black

        loadingView = dimmedLoadingView
        self.title = moment?.name.value
        // Do any additional setup after loading the view.
        validateRequest = moment.validate({ [weak self](success, error) in
            if success {
                self?.loadData(dimmedLoadingView)
            } else {
                DispatchQueue.main.async { [weak self] in
                    let alert = UIAlertController.cancellableAlertConroller("Unable to validate the moment", message: error?.localizedDescription, handler: nil)
                    self?.present(alert, animated: true, completion: nil)
                    self?.reloadCollectionView()
                    dimmedLoadingView.removeFromSuperview()
                }
            }
        })
    }

    fileprivate func reloadCollectionView() {
        self.updateItemSizes()
        self.collectionView?.reloadData()
    }
    
    func loadData(_ view: UIView?) {

        _ = GalleryMomentRequest.getGalleries(moment: self.moment, all: true, approved: true) { [weak self](data, error) -> Void in
            OperationQueue.main.addOperation {
                self?.data = data ?? GalleryMomentData()
                self?.reloadCollectionView()
                view?.removeFromSuperview()
            }
        }.execute()
    }

    fileprivate func updateItemSizes() {
        if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            if data?.fileEntities.count == 0 {
                layout.itemSize = CGSize(width: self.view.frame.width, height: 60)
                layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
            } else {
                if viewType == "Grid" {
                    layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                    let width = self.view.frame.width - 40 / 2.0
                    layout.itemSize = CGSize(width: width, height: width)
                } else {
                    layout.minimumInteritemSpacing = 0
                    layout.minimumLineSpacing = 0
                    layout.sectionInset = UIEdgeInsets.zero
                    layout.itemSize = self.view.frame.size
                }
            }
        }
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
        imageQ.cancelAllOperations()
        _ = validateRequest?.cancel()
        requestTask?.cancel()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadingView?.frame = self.view.frame
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return data == nil ? 0 : max(data?.fileEntities.count ?? 1, 1) // data == nil means its loading data...
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let entities = data?.fileEntities , entities.count > 0 {
            
            if viewType == "Grid" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
                let item = entities[(indexPath as NSIndexPath).item]
                
                let oprn = CustomOprn {
                    guard let url = URL(string: item.fileURL), let data = try? Data(contentsOf: url) else {
                        return
                    }
                    let img = UIImage(data: data)
                    OperationQueue.main.addOperation({
                        if let cell = collectionView.cellForItem(at: indexPath), let imgView = cell.viewWithTag(1) as? UIImageView {
                            imgView.image = img ?? UIImage(named: "ic_image_loading_placeholder")
                            imgView.setNeedsDisplay()
                        }
                    })
                }
                oprn.fileId = item.fileID
                imageQ.addOperation(oprn)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierSingle, for: indexPath)
                let item = entities[(indexPath as NSIndexPath).item]
                let galleryView = cell.viewWithTag(1) as? SingleGalleryView
                
                galleryView?.image = UIImage(named: "ic_image_loading_placeholder")
                if let url = URL(string: item.fileURL), let img = self.imageCache.object(forKey: "\(url.absoluteString)" as NSString) {
                    galleryView?.image = img
                } else {
                    let oprn = CustomOprn {
                        guard let url = URL(string: item.fileURL), let data = try? Data(contentsOf: url) else {
                            return
                        }
                        let img = UIImage(data: data)
                        OperationQueue.main.addOperation({
                            if let _ = collectionView.cellForItem(at: indexPath), let galleryView = galleryView {
                                galleryView.image = img ?? UIImage(named: "ic_image_loading_placeholder")
                                if let img = img {
                                    self.imageCache.setObject(img, forKey: "\(url.absoluteString)" as NSString)
                                } else {
                                    self.imageCache.removeObject(forKey: "\(url.absoluteString)" as NSString)
                                }
                            }
                        })
                    }
                    oprn.fileId = item.fileID
                    imageQ.addOperation(oprn)
                }
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierLoaderCell, for: indexPath)
//            print(cell.frame)
            let label = cell.viewWithTag(1) as! UILabel
            label.text = "No images available"
            return cell
        }
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "mm_image_gallery") as? GalleryCollectionViewController else {
            return
        }
        vc.moment = self.moment
        vc.data = self.data
        vc.viewType = "Single"
        self.navigationController?.pushViewController(vc, animated: true)
    }

    open class GalleryMomentData: ResponseObjectSerializable {

        open class GalleryData : NSObject {
            open var fileID: Int
            open var fileURL: String
            open var fileType: String?
            open var fileName: String?
            open var serviceId: String?
            open var galleryDescription: String?
            open var title: String?
            open var uniqueId: String?
            open var confirmationServer: String?
            open var dateAdded: String?
            open var dateModified: String?

            init?(dictionary: NSDictionary) {

                fileID      = dictionary.numForKey("fileId")?.intValue ?? 0
                uniqueId    = dictionary.value(forKey: "uniqueId") as? String
                title       = dictionary.htmlDecodedString("title")
                fileURL     = dictionary.value(forKey: "fileURL") as? String ?? ""
                fileType    = dictionary.htmlDecodedString("fileType")
                fileName    = dictionary.htmlDecodedString("fileName")
                galleryDescription  = dictionary.htmlDecodedString("description")
                serviceId           = dictionary.value(forKey: "serviceId") as? String
                confirmationServer  = dictionary.value(forKey: "confirmationServer") as? String
                dateAdded           = dictionary.value(forKey: "dateAdded") as? String
                dateModified        = dictionary.value(forKey: "dateModified") as? String
            }

        }

        open var fileEntities:[GalleryData] = []
        open var type: String = "grid"

        public init() { }
        public init?(dictionary: NSDictionary) {
            readFromDictionary(dictionary)
        }

        public required init?(response: HTTPURLResponse, representation: AnyObject) {
            guard let rep = representation as? NSDictionary else {
                return nil
            }
            readFromDictionary(rep)
        }

        fileprivate func readFromDictionary(_ dictionary: NSDictionary) {
            let webs = dictionary.value(forKey: "fileEntities") as? [[String:AnyObject]]

            if let webs = webs {
                for data in webs {
                    if let item = GalleryData(dictionary: data as NSDictionary) {
                        fileEntities.append(item)
                    }
                }
            }

            type = dictionary.value(forKey: "type") as? String ?? "grid"
        }
        
    }
}

class CustomOprn : BlockOperation {
    var fileId: Int = 0
}


enum GalleryMomentRequest : Requestable {

    // --- cases
    case getGalleries(moment: Moment, all: Bool?, approved: Bool?, completion:(_ data: GalleryCollectionViewController.GalleryMomentData?, _ error: NSError?) -> Void)

    // --- 'override' functions
    var requestType: FlybitsSDK.FlybitsRequestType { return .custom }
    var method: FlybitsSDK.HTTPMethod { return .GET }
    var encoding: HTTPEncoding { return .url }
    var path: String { return "" }
    var headers: [String : String] { return ["Accept-Language" : "en"] }

    var baseURI: String {
        switch self {
        case let .getGalleries(moment, all, approved, _):

            // `/galleries?getAll=true&isApprovedtrue`
            var path:String = ""
            if let all = all {
                path += "?getAll=\(all ? "true":"false" )"
            }

            if let approved = approved {
                // has getAll already appended then append path with `&` else start with `?`
                if path.hasPrefix("?") {
                    path += "&"
                } else {
                    path += "?"
                }
                path += "isApproved=\(approved ? "true":"false" )"
            }
            return moment.launchURL + "/Galleries" + (path)
        }
    }

    func execute() -> FlybitsSDK.FlybitsRequest {
        switch self {
        case .getGalleries(_, _, _, let completion):
            return FlybitsRequest(urlRequest).response { (request, response, data: GalleryCollectionViewController.GalleryMomentData?, error) -> Void in
                completion(data, error)
            }
        }
    }
}



