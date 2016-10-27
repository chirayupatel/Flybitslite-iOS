//
//  ChangePasswordViewController.swift
//  Flybits
//
//  Created by chu on 2015-08-27.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

class ChangePasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fieldOriginalPassword: SeparatedTextfield!
    @IBOutlet weak var fieldNewPassword: SeparatedTextfield!
    @IBOutlet weak var fieldRetypePassword: SeparatedTextfield!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeholderAttribDict = [ NSForegroundColorAttributeName : UIColor(red: 0.6471, green: 0.7412, blue: 0.8078, alpha: 1.0) /* #a5bdce */ ]
        let prepare: (_ f: SeparatedTextfield, _ returnType: UIReturnKeyType) -> Void = { (f, r) in
            if let placeholder = f.textfield.placeholder {
                f.textfield.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeholderAttribDict)
            }
            f.textfield.delegate = self
            f.textfield.returnKeyType = UIReturnKeyType.next
            f.textfield.autocorrectionType = UITextAutocorrectionType.no
            f.textfield.autocapitalizationType = UITextAutocapitalizationType.none
        }

        prepare(fieldNewPassword, .next)
        prepare(fieldOriginalPassword, .next)
        prepare(fieldRetypePassword, .done)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: OperationQueue.main) { [weak self](notification) -> Void in
            self?.keyboardWillShow(notification)
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { [weak self](notification) -> Void in
            self?.keyboardWillHide(notification)
        }

        
        let closeImage = UIImage(named: "ic_close_b")!.resize(CGSize(width: 15, height: 15), scale: UIScreen.main.scale).withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: closeImage, style: UIBarButtonItemStyle.done, target: self, action: #selector(ChangePasswordViewController.exitWithoutSaving(_:)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func exitWithoutSaving(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "UnwindToProfileView", sender: sender)
    }

    fileprivate func keyboardWillShow(_ notification:Notification) {
        if let frame = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
            self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, frame.height, 0)
        }
    }
    
    fileprivate func keyboardWillHide(_ notification:Notification) {
        self.scrollView.contentInset = UIEdgeInsets.zero
    }
    

    @IBAction func savedButtonTapped(_ sender: ThemedButton) {
        changePassword()
    }
    
    func changePassword() {
        
        guard let newPassword = fieldNewPassword?.text, let newPassword2 = fieldRetypePassword?.text , newPassword == newPassword2 else {
            
            fieldNewPassword.displayErrorImage = true
            fieldRetypePassword.displayErrorImage = true
            fieldNewPassword.displayErrorView()
            fieldRetypePassword.displayErrorView()
            return
        }
        
        guard let oldPassword = fieldOriginalPassword?.text , oldPassword.characters.count > 0 else {
            fieldOriginalPassword.displayErrorImage = true
            fieldOriginalPassword.displayErrorView()
            return
        }

        _ = AccountRequest.updatePassword(from: oldPassword, to: newPassword) { (error) in
            if Utils.ErrorChecker.noInternetConnection(error) {
                OperationQueue.main.addOperation {
                    let alert = UIAlertController.cancellableAlertConroller(NSLocalizedString("NO_INTERNET_CONNECTION", comment:""), message: nil, handler: nil)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }

            if Utils.ErrorChecker.isAccessDenied(error) {
                Utils.UI.takeUserToLoginPage()
                return
            }
            
            OperationQueue.main.addOperation {
                if error == nil {
                    self.performSegue(withIdentifier: "UnwindToProfileView", sender: nil)
                } else if let obj = error?.userInfo[NSLocalizedDescriptionKey] as? NSData, let errorJsonString = String(data: obj as Data, encoding: String.Encoding.utf8),
                    let errorJsonData = errorJsonString.data(using: .utf8),
                let errorJsonDict = try? JSONSerialization.jsonObject(with: errorJsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject] {
                        let str = errorJsonDict?["exceptionMessage"] as? String ?? "Unable to save your profile"
                        let alert = UIAlertController.cancellableAlertConroller("Error saving profile", message: str, handler: nil)
                        self.present(alert, animated: true, completion: nil)
                        
                } else if let error = error?.localizedDescription {
                    let alert = UIAlertController.cancellableAlertConroller("Error saving profile", message: error, handler: nil)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController.cancellableAlertConroller("Error saving profile", message: nil, handler: nil)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }.execute()
    }
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

 
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case fieldOriginalPassword.textfield:
            fieldNewPassword.textfield.becomeFirstResponder()
            return false
        case fieldNewPassword.textfield:
            fieldRetypePassword.textfield.becomeFirstResponder()
            return false
        case fieldRetypePassword.textfield:
            fieldRetypePassword.textfield.resignFirstResponder()
            changePassword()
            return true
        default:
            // UNREGISTERED TEXTFIELD?
            abort()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == fieldOriginalPassword.textfield {
            fieldOriginalPassword.removeErrorView()
        } else if textField == fieldNewPassword.textfield {
            fieldNewPassword.removeErrorView()
        } else if textField == fieldRetypePassword.textfield {
            fieldRetypePassword.removeErrorView()
        }
        self.removeErrorBanner()
    }

}
