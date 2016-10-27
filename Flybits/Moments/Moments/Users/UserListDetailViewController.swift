//
//  UserDetailViewController.swift
//  Flybits
//
//  Created by chu on 2015-10-18.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit

class UserListDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!

    @IBOutlet weak var btnSocialFacebook: UIButton!
    @IBOutlet weak var btnSocialTwitter: UIButton!
//    @IBOutlet weak var btnSocialLinkedIn: UIButton!
    @IBOutlet weak var btnSocialInstagram: UIButton!

    @IBOutlet weak var descriptionLabel: UILabel!


    var item: UsersMomentCollectionViewController.UsersMomentData.DataItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateUI()

    }

    func updateUI() {
        assert(item != nil)

        let d = item.preferredLocalizedItem(UsersMomentCollectionViewController.CurrentLocaleCode)

        let queue = OperationQueue()
        queue.addOperation {
            if let imgurl = self.item.imageUrl, let url = URL(string: imgurl), let data = try? Data(contentsOf: url) {
                OperationQueue.main.addOperation {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }

        btnSocialFacebook.isHidden = d?.facebookUrl == nil
        btnSocialTwitter.isHidden = d?.twitterUrl == nil
//        btnSocialLinkedIn.hidden = true
        btnSocialInstagram.isHidden = d?.instagramUrl == nil

        titleLabel.text = d?.fullname.XMLEntitiesDecode() ?? ""
        subtitleLabel.text = d?.position?.XMLEntitiesDecode() ?? "-"

        if let email = d?.email {
            emailButton.setTitle(email, for: UIControlState())
            emailButton.isHidden = false
        } else {
            emailButton.isHidden = true
        }

        if let phone = d?.phoneNumber {
            phoneButton.setTitle(phone, for:
                UIControlState())
            phoneButton.isHidden = false
        } else {
            phoneButton.isHidden = true
        }


        descriptionLabel.text = d?.aboutMe?.XMLEntitiesDecode() ?? ""
    }

    @IBAction func phoneButtonTapped(_ button: UIButton) {
        let phontTitle = button.title(for: UIControlState())?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
        guard let phone = phontTitle, 
            let url = URL(string: "tel:" + phone)
            , UIApplication.shared.openURL(url) else {

            let vc = UIAlertController.cancellableAlertConroller("Invalid phone number", message: nil, handler: nil)
            self.present(vc, animated: true, completion: nil)
            return
        }
    }

    @IBAction func emailButtonTapped(_ button: UIButton) {

        guard let email = button.title(for: UIControlState()),
            let url = URL(string:"mailto:"+email)
            , UIApplication.shared.openURL(url) else {

            let vc = UIAlertController.cancellableAlertConroller("Invalid email address", message: nil, handler: nil)
            self.present(vc, animated: true, completion: nil)
            return
        }
    }

    @IBAction func socialButtonTapped(_ sender: UIButton) {

        let d = item.preferredLocalizedItem(UsersMomentCollectionViewController.CurrentLocaleCode)

        switch sender {
        case btnSocialFacebook:
            if let url = d?.facebookUrl {
                UIApplication.shared.openURL(URL(string: url)!)
            } else {
                let controller = UIAlertController(title: "Facebook page is unavailable", message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
            
        case btnSocialInstagram:
            if let url = d?.instagramUrl {
                UIApplication.shared.openURL(URL(string: url)!)
            } else {
                let controller = UIAlertController(title: "Instagram page is unavailable", message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }


//        case btnSocialLinkedIn:
//            let controller = UIAlertController(title: "LinkedIn profile unavailable", message: nil, preferredStyle: .Alert)
//            controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
//            self.present(controller, animated: true, completion: nil)

        case btnSocialTwitter:
            if let url = d?.twitterUrl {
                UIApplication.shared.openURL(URL(string: url)!)
            } else {
                let controller = UIAlertController(title: "Twitter page in unavailable", message: nil, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }

        default: break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let imageView = imageView {
            imageView.layer.cornerRadius = imageView.frame.size.height/2.0
            imageView.layer.masksToBounds = true
        }

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
