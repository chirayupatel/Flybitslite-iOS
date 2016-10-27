//
//  UserProfileViewController.swift
//  Flybits
//
//  Created by Archuthan Vijayaratnam on 2016-07-18.
//  Copyright © 2016 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

class UserProfileViewController: UIViewController {
    @IBOutlet weak var imageView: LoadableImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var viewAllZonesBtn: UIButton!

    fileprivate var loadingView = LoadingView()

    var gettingUser: Bool = false
    var user: User? {
        didSet {
            updateUI()
        }
    }
    
    var imageRequest: FlybitsRequest!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = user {
            updateUI()
        }
    }
    
    fileprivate func updateUI() {
        imageView?.image = user?.profile?.image?.loadedImage(forSize: ._60, for: nil)
        nameLabel?.text = user?.profile?.fullName
        emailLabel?.text = user?.profile?.email
        
        if let _ = imageView {
            loadImage()
        }
    }
    
    @IBAction func viewAllZonesButtonTapped(_ sender: AnyObject) {
        let zoneController = self.storyboard?.instantiateViewController(withIdentifier: "ZonesVC") as? ZonesCollectionViewController
        zoneController!.viewType = .usersZone
        zoneController?.title = self.user?.profile?.fullName
        zoneController!.querySetupCallback = { q in
            if let user = self.user {
                q.userIDs = [user.identifier]
            }
            return q
        }
        self.navigationController?.pushViewController(zoneController!, animated: true)
    }
    
    func loadImage() {
        guard user?.profile?.image?.loadedImage(forSize: ._60, for: nil) == nil else {
            OperationQueue.main.addOperation {  [weak self] in
                self?.imageView.image = self?.user?.profile?.image?.loadedImage(forSize: ._60, for: nil)
                self?.imageView.loading = false
            }
            return
        }
        
        _ = imageRequest?.cancel()
        imageView?.loading = true
        imageRequest = user?.profile?.image?.loadImage(forSize: ._60, for: nil, completion: { (image, error) in
            OperationQueue.main.addOperation {  [weak self] in
                self?.imageView.image = image.loadedImage(forSize: ._60, for: nil)
                self?.imageView.loading = false
            }
        })
    }
    
    func loadUserProfile(_ userId: String) {
        guard gettingUser == false else { return }
        
        view.addSubview(loadingView)
        gettingUser = true
        _ = UserRequest.getUser(userID: userId) { [weak self] user, error in
            OperationQueue.main.addOperation {
                self?.user = user
                self?.gettingUser = false
                self?.loadingView.removeFromSuperview()
            }
        }.execute()
    }
}


class LoadableImageView : UIImageView {
    var loading: Bool = false {
        didSet {
            updateStatus()
        }
    }
    
    override var image: UIImage? {
        didSet {
            if image == nil {
                image = UIImage(named: "ic_image_loading_placeholder")
            }
        }
    }
    
    fileprivate var loadingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(loadingView)
    }
    
    fileprivate func updateStatus() {
        if loading {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        loadingView.center = self.center
    }
}

