//
//  ProfileViewController.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-13.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK
import SafariServices

class ThemedSliderCell : UITableViewCell {
    
    var settingValues: SliderRange<Float>! {
        didSet {
            updateSettingValues()
        }
    }
    
    fileprivate func updateSettingValues() {
        guard slider != nil && settingValues != nil && valueChanged != nil else { return }
        slider.minimumValue = settingValues.min
        slider.maximumValue = settingValues.max
        update(Float(settingValues.defaultValue))
    }
    
    var valueChanged: ((_ slider: ThemedSliderCell) -> Void)!
    var updateLabel: ((_ slider: ThemedSliderCell, _ value:Float, _ label:UILabel) -> Void)!

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UILabel!
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.valueChanged(self)
        self.updateLabel(self, sender.value, value)
    }
    
    func update(_ newValue:Float?) {
        if let newValue = newValue {
            self.slider.setValue(newValue, animated: false)
            self.updateLabel(self, slider.value, value)
        }
    }
}

class ProfileViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var versionString: UILabel!
    @IBOutlet weak var fieldName: SeparatedTextfield!
    @IBOutlet weak var fieldLastname: SeparatedTextfield!
    @IBOutlet weak var fieldEmail: SeparatedTextfield!
    
    @IBOutlet weak var cellZoneDiscoveryRange: ThemedSliderCell!

    @IBOutlet weak var btnUserAvatar: UserAvatar!
    @IBOutlet weak var btnFacebookConnection: ThemedButton!

    var loadingView: UIView?
    var originalProfile: User?
    var user: User? {
        didSet {
            self.originalProfile = user
        }
    }

    var btnSave: UIBarButtonItem!
    var btnCancel: UIBarButtonItem!

    var originalNavButtons:(left:[UIBarButtonItem]?, right:[UIBarButtonItem]?)

    override func viewDidLoad() {
        if let navBar = navigationController?.navigationBar {
            navBar.isTranslucent = false
            navBar.tintColor = UIColor.primaryButtonColor()
            navBar.backgroundColor = UIColor.purple
            navBar.barTintColor = UIColor.white
            navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.primaryButtonColor()]
        }

        super.viewDidLoad()

        // set it to nil so we can reload the user's profile again incase if it has any changes
        self.user = nil
        versionString.text = Utils.buildVersionString()
        originalNavButtons = (self.navigationItem.leftBarButtonItems, self.navigationItem.rightBarButtonItems)
        
        fieldName.textfield.delegate = self
        fieldName.separatorVisible = false
        fieldLastname.textfield.delegate = self
        fieldLastname.separatorVisible = false
        fieldEmail.textfield.isEnabled = false
        fieldEmail.textfield.delegate = self
        fieldEmail.separatorVisible = false

        btnSave = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ProfileViewController.saveBtnTapped(_:)))

        btnCancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ProfileViewController.cancelBtnTapped(_:)))

        
        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingView = dimmedLoadingView
        getUserProfile()

        cellZoneDiscoveryRange.updateLabel = { (slider, value, label) in
            label.text = "\(floorf(value)) m"
        }
        cellZoneDiscoveryRange.valueChanged = { (slider) in
            let sender = slider.slider
            UserDefaults.standard.set(Int((sender?.value)!), forKey: AppConstants.UserDefaultKey.ZoneDiscoveryValue)
            UserDefaults.standard.synchronize()
        }

        cellZoneDiscoveryRange.settingValues = AppConstants.Configs.ZoneDiscoveryRange
        
        let def = UserDefaults.standard
        let value1 = def.float(forKey: AppConstants.UserDefaultKey.ZoneDiscoveryValue)
        cellZoneDiscoveryRange.update(value1)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        btnUserAvatar.layer.cornerRadius = btnUserAvatar.frame.size.height/2.0
        btnUserAvatar.layer.masksToBounds = true
        btnUserAvatar.layer.borderWidth = 2.0
        btnUserAvatar.layer.borderColor = UIColor.white.cgColor
    }
    
    @IBAction func backToProfileViewController(_ segue:UIStoryboardSegue) {
        
    }

    func getUserProfile() {

        if user == nil {
            _ = UserRequest.getSelf(completion: { [weak self](user, error) -> Void in
                OperationQueue.main.addOperation { [weak self] in
                    if Utils.ErrorChecker.noInternetConnection(error) {
                        _ = self?.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                        return
                    }
                    
                    if Utils.ErrorChecker.isAccessDenied(error) {
                        Utils.UI.takeUserToLoginPage()
                        return
                    }
                    

                    self?.user = user
                    self?.originalProfile = user
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppConstants.Notifications.UserProfileUpdated), object: user)
                    self?.updateUI()
                }
            }).execute()
        } else {
            OperationQueue.main.addOperation { [weak self] in
                self?.updateUI()
            }
        }
    }

    func updateUI() {

        if let p = user?.profile {
            fieldName?.text = p.firstname!
            fieldLastname?.text = p.lastname!
            fieldEmail?.text = p.email

            loadingView?.removeFromSuperview()
            _ = ImageRequest.download100(p.image!, completion: { [weak self](image, error) -> Void in
                OperationQueue.main.addOperation { [weak self] in
                    if let img = image {
                        self?.btnUserAvatar?.setImage(img, for: .normal)
                    }
                }
            }).execute()
        } else {
            loadingView?.removeFromSuperview()
            var alert: UIAlertController? = nil
            alert = UIAlertController.cancellableAlertConroller("Couldn't load profile", message: "Unable to load your profile", handler: { (cancel) -> Void in
                alert?.dismiss(animated: true, completion: nil)
            })
            self.present(alert!, animated: true, completion: nil)
        }
    }

    //MARK: TextfieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        removeErrorBanner()
        var beganEditing = false
        switch textField {
        case fieldName.textfield:
            fieldName.separatorVisible = true
            fieldEmail.separatorVisible = false
            fieldLastname.separatorVisible = false
            beganEditing = true
        case fieldLastname.textfield:
            fieldEmail.separatorVisible = false
            fieldName.separatorVisible = false
            fieldLastname.separatorVisible = true
            beganEditing = true
            
        case fieldEmail.textfield:
            fieldName.separatorVisible = false
            fieldLastname.separatorVisible = false
            fieldEmail.separatorVisible = true
            beganEditing = true
        default:
            do {
                abort()
            }
        }

        updateNavigationButtons(beganEditing)
    }
    
    func checkNameField() -> (errorFirstname:String?, errorLastname:String?) {
        var firstError: String? = "Firstname must be 2 or more characters"
        var secondError: String? = "Lastname must be 2 or more characters"
        
        if let name = fieldName.text , name.characters.count > 1 {
            firstError = nil
        }
        if let name = fieldLastname.text , name.characters.count > 1 {
            secondError = nil
        }
        return (firstError, secondError)
    }
    
    func updateNavigationButtons(_ visible:Bool) {
        if visible {
            self.navigationItem.rightBarButtonItem = btnSave
            self.navigationItem.leftBarButtonItem = btnCancel
            self.navigationItem.hidesBackButton = true
        } else {
            self.navigationItem.rightBarButtonItems = originalNavButtons.right
            self.navigationItem.leftBarButtonItems = originalNavButtons.left
            self.navigationItem.hidesBackButton = false
        }
    }

    func saveBtnTapped(_ sender:UIBarButtonItem) {
        originalProfile = Session.sharedInstance.currentUser
        
        _ = fieldEmail.resignFirstResponder()
        _ = fieldName.resignFirstResponder()
        
        let errors = checkNameField()
        if errors.errorFirstname != nil {
            fieldName.displayErrorImage = true
            _ = displayErrorMessage(errors.errorFirstname!)
            return
        }
        if errors.errorLastname != nil {
            fieldLastname.displayErrorImage = true
            _ = displayErrorMessage(errors.errorLastname!)
            return
        }
        
        guard let firstname = fieldName?.text else {
            fieldName.displayErrorImage = true
            return
        }
        
        guard let lastname = fieldLastname?.text else {
            fieldLastname.displayErrorImage = true
            return
        }

        // since SDK resets the currentUser object when the saves fails... save the object...
        let oldUser = Session.sharedInstance.currentUser
        let oldFirstname = Session.sharedInstance.currentUser?.profile?.firstname
        let oldLastname = Session.sharedInstance.currentUser?.profile?.lastname
        
        let query = AccountQuery()
        query.firstname = firstname
        query.lastname = lastname
//        query.email = email

        Session.sharedInstance.currentUser?.profile?.firstname = firstname
        Session.sharedInstance.currentUser?.profile?.lastname = lastname
        
        assert(Session.sharedInstance.currentUser != nil, "current user is nil")
        _ = AccountRequest.updateDetails { [weak self](user, error) -> Void in
            
            OperationQueue.main.addOperation { [weak self] in
            
                if Utils.ErrorChecker.noInternetConnection(error) {
                    Session.sharedInstance.currentUser = oldUser
                    Session.sharedInstance.currentUser?.profile?.firstname = oldFirstname
                    Session.sharedInstance.currentUser?.profile?.lastname = oldLastname
                    _ = self?.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                    self?.updateNavigationButtons(false)
                    return
                }
                
                assert(Session.sharedInstance.currentUser != nil, "current user shouldn't be nil")
                if user != nil {
                        self?.originalProfile = user
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppConstants.Notifications.UserProfileUpdated), object: user)
                        
                        _ = self?.displaySuccessMessage("Profile updated")
                        
                        Delay(1.5) { [weak self] in
                            self?.removeErrorBanner()
                        }
                } else {
                    
                    _ = self?.displayErrorMessage("Unable to save profile")
                    Delay(1.5) { [weak self] in
                        self?.removeErrorBanner()
                    }
                    Session.sharedInstance.currentUser = oldUser
                    Session.sharedInstance.currentUser?.profile?.firstname = oldFirstname
                    Session.sharedInstance.currentUser?.profile?.lastname = oldLastname
                }
                self?.updateNavigationButtons(false)
            }

        }.execute()
    }

    func cancelBtnTapped(_ sender:UIBarButtonItem) {
        removeErrorBanner()
        //TODO: Reset the data back to original. If user already edited name, should reset it back to w/e it was before

        self.user = self.originalProfile
        
        fieldName.textfield.resignFirstResponder()
        fieldEmail.textfield.resignFirstResponder()

        fieldName.separatorVisible = false
        fieldEmail.separatorVisible = false

        updateNavigationButtons(false)
        self.updateUI()
    }

    func presentImagePicker(_ souce:UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = souce
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func userAvatarTapped(_ sender: UIButton) {
//        print(sender)

        let alert = UIAlertController(title: "Upload avatar:", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        if UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.camera) != nil {
            alert.addAction(UIAlertAction(title: "Camera", style: UIAlertActionStyle.default, handler: { [weak self](action) -> Void in
                self?.presentImagePicker(UIImagePickerControllerSourceType.camera)
            }))
        }

        if UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.photoLibrary) != nil {
            alert.addAction(UIAlertAction(title: "Photos", style: UIAlertActionStyle.default, handler: { [weak self](action) -> Void in
                self?.presentImagePicker(UIImagePickerControllerSourceType.photoLibrary)
            }))
        }
        
        if UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.savedPhotosAlbum) != nil {
            alert.addAction(UIAlertAction(title: "Saved Photos", style: UIAlertActionStyle.default, handler: { [weak self](action) -> Void in
                self?.presentImagePicker(UIImagePickerControllerSourceType.savedPhotosAlbum)
            }))
        }


        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
            
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if let cell = tableView.cellForRow(at: indexPath), let identifier = cell.reuseIdentifier , ["logoutcell", "privacycell", "aboutcell"].contains(identifier) {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let identifier = tableView.cellForRow(at: indexPath)?.reuseIdentifier {
            switch identifier {
            case "logoutcell":
                Utils.UI.presentLogoutUI(self.view.bounds, controller: self)
            case "privacycell":
                presentPrivacyPolicyUI()
            case "aboutcell":
                presentAboutUI()
            default:
                break
            }
        }
    }
    
    fileprivate func uploadImage(_ image:UIImage, completion:@escaping (_ success:(imageID:String, userID:String)?, _ error:NSError?)->Void) {
        
        _ = AccountRequest.updateImageWithImage(image: image) { [weak self](user, error) -> Void in
            OperationQueue.main.addOperation { [weak self] in
                
                if Utils.ErrorChecker.isAccessDenied(error) {
                    Utils.UI.takeUserToLoginPage()
                    return
                }
                if Utils.ErrorChecker.noInternetConnection(error) {
                    _ = self?.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                    self?.updateNavigationButtons(false)
                    return
                }
                
                
                if let url = user?.profile?.image?.url()?.value {
                    completion((url, user!.identifier), error)
                    if let user = user {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppConstants.Notifications.UserProfileUpdated), object: user)
                    }
                } else {
                    completion(nil, error)
                }
            }
        }.execute()
    }
    
    //MARK :
    func presentPrivacyPolicyUI() {

        let URLString = "http://flybits.com/eula/"
        if #available(iOS 9.0, *) {
            let svc = SFSafariViewController(url: URL(string: URLString)!)
            self.present(svc, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
            if let webVC =  self.storyboard?.instantiateViewController(withIdentifier: "flybits_generic_web") as? GenericWebViewController {
                webVC.URLString = URLString
                self.navigationController?.pushViewController(webVC, animated: true)
            }
        }
    }

    func presentAboutUI() {
        let URLString = Bundle.main.path(forResource: "license_used", ofType: "html")!
        // Fallback on earlier versions
        if let webVC =  self.storyboard?.instantiateViewController(withIdentifier: "flybits_generic_web") as? GenericWebViewController {
            webVC.URLString = URLString
            self.navigationController?.pushViewController(webVC, animated: true)
        }
    }
    @IBAction func manageContextsButtonTapped(_ sender: AnyObject) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "onboarding_context") as? ContextOnBoardingViewController {
            vc.navigationItem.rightBarButtonItem = BarButtonItem(title: "Save", callback: { (bar) in
                vc.saveConfiguration()
                _ = vc.navigationController?.popViewController(animated: true)
            })
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    //MARK : UIImagePickerViewControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            OperationQueue.main.addOperation{ [weak self] in
                self?.btnUserAvatar.startAnimatingBorder()
            }
            Delay(1) { [weak self] in
                let newImage = pickedImage.resizeWithAspect(200, height: nil)
                self?.uploadImage(newImage, completion: { [weak self](success, error) -> Void in
                    OperationQueue.main.addOperation{
                        if let _ = success?.imageID , error == nil {
                            self?.btnUserAvatar.setImage(newImage, for: UIControlState())
                        } else if let msg = error?.localizedDescription {
                            _ = self?.displayErrorMessage(msg)
                        }
                        self?.btnUserAvatar.stopAnimatingBorder()
                    }
                })
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

}
