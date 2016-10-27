//
//  ForgotPasswordViewController.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-11.
//  Copyright © 2015 Flybits. All rights reserved.
//

import UIKit
import FlybitsSDK

class ForgotPasswordViewController: UITableViewController, UITextFieldDelegate {

    var request: FlybitsRequest? = nil
    @IBOutlet weak var fieldEmail: SeparatedTextfield!
    override func viewDidLoad() {
        super.viewDidLoad()
        fieldEmail.textfield.delegate = self
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeErrorBanner()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _ = request?.cancel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func forgotPasswordButtonTapped(_ sender: ThemedButton) {

        guard let email = fieldEmail.text?.lowercased() , email.characters.count > 0 else {
            self.fieldEmail.displayErrorView()
            _ = displayErrorMessage("Enter your email")
            return
        }

        _ = fieldEmail.resignFirstResponder()

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.startAnimating()

        sender.imageView?.image = UIImage()
        sender.imageView?.addSubview(activityIndicator)
        request = AccountRequest.forgotPassword(email: email) { (error) -> Void in
            if Utils.ErrorChecker.noInternetConnection(error) {
                _ = self.displayErrorMessage(NSLocalizedString("NO_INTERNET_CONNECTION", comment: ""))
                activityIndicator.removeFromSuperview()
                return
            }

            guard let error = error else {
                // success
                OperationQueue.main.addOperation({
                    let alert = UIAlertController(title: "Email is sent", message: "Follow the instruction in the email to reset your password", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
                        _ = self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                })
                return
            }


            self.fieldEmail.displayErrorView()
            
            OperationQueue.main.addOperation({
                let err = Utils.ErrorChecker.formatError(error)
                _ = self.displayErrorMessage(err.localizedDescription)
            })
            activityIndicator.removeFromSuperview()
        }.execute()
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == fieldEmail.textfield {
            fieldEmail.removeErrorView()
            removeErrorBanner()
        }
    }

}
