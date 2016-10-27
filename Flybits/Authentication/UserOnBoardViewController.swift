//
//  UserOnBoardViewController.swift
//  Flybits
//
//  Created by chuthan20 on 2015-08-12.
//  Copyright © 2015 Flybits. All rights reserved.
//

import Foundation
import UIKit
import FlybitsSDK
import LocalAuthentication

enum Result {
    case success
    case error(Error)
    case userCancelled
}

protocol UserOnBoardDelegate : class {
    func userOnBoard(_ controller:UserOnBoardViewController, result:Result, viewType:UserOnBoardViewController.ViewType)
}

//TODO: Should rename this to Something else, OnBoarding doesn't make sense for this?
//TODO: Refactor me! - separate login/register/forgot password into their own view controllers?
class UserOnBoardViewController: UIViewController, UITextFieldDelegate {
    typealias LoginViewController = UserOnBoardViewController // login, registration happens in this view controller
    
    enum ViewType {
        case login
        case register
        case forgotPassword
    }

    var backgroundImageView = UIImageView(image: AppConstants.UI.UserOnBoardBackgroundImage)

    var viewType: ViewType = ViewType.login

    var constraintsLoginView:[NSLayoutConstraint] = []
    var constraintsForgotPassword:[NSLayoutConstraint] = []
    var constraintsCreateAccount:[NSLayoutConstraint] = []
    var constraintsTransition:[NSLayoutConstraint] = []

    var containerLogo: LogoContainerView!
    var fieldFirstName: SeparatedTextfield!
    var fieldLastName: SeparatedTextfield!
    var fieldEmail: SeparatedTextfield!
    var fieldPassword: SeparatedTextfield!

    var btnClose: UIButton!
    var btnForgotPassword: ThemedButton!
    var btnTakeOff: ThemedButton!
    var btnCreateAccount: UIButton!

    var containerCreateAccount: UIView!

    var allContainerView = UIView()
    var scrollView = UIScrollView()
    var errorView: UIView = UIView()

    weak var delegate: UserOnBoardDelegate?

    let autoLayoutMetrics = ["fHeight":45, "bHeight":45, "logoHeight":50]
    let autoLayoutFormatOptions = NSLayoutFormatOptions(rawValue: 0)
    let animDuration: TimeInterval = 0.3

    var request: FlybitsRequest!
    
    var animateLogoLoading: Bool = false {
        didSet {
            containerLogo.animateLoading = animateLogoLoading
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("deinit \(self)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundImageView.contentMode = UIViewContentMode.scaleAspectFill
        view.addSubview(backgroundImageView)

        scrollView.addSubview(allContainerView);
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        allContainerView.translatesAutoresizingMaskIntoConstraints = false
        allContainerView.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: UILayoutConstraintAxis.vertical)
        // constraint scrollview to parent view
        var scrollViewConstraints = [NSLayoutConstraint]()
        scrollViewConstraints.append(contentsOf: EqualConstraints(scrollView, view, [.leading, .trailing, .height, .centerX, .centerY]))
        NSLayoutConstraint.activate(scrollViewConstraints)

        // constraint wrapper view to scrollView (all the views (buttons/labels/fields) should be added allContainerView)
        var constraintsParentView:[NSLayoutConstraint] = []
        constraintsParentView.append(contentsOf: EqualConstraints(allContainerView, scrollView, [.leading, .trailing, .height, .centerX, .centerY]))

        constraintsParentView.append(contentsOf: EqualConstraints(allContainerView, view, [.width]))
        NSLayoutConstraint.activate(constraintsParentView)

        createAllViews()
        createLoginConstraints()
        NSLayoutConstraint.activate(constraintsLoginView)
        setLoginVisibleViews()

        if AppConstants.Configs.SupportTouchID {
            if Session.sharedInstance.lite_canLoginUsingSessionToken() && isTouchIDAvailable() {
                populateLoginFieldsUsingTouchID { (success, error) -> Void in
                    if ( success ) {
                        OperationQueue.main.addOperation {
                            self.loginUsingRememberMe()
                        }
                    }
                }
            } else if Session.sharedInstance.lite_canLoginUsingSessionToken() {
                OperationQueue.main.addOperation {
                    self.loginUsingRememberMe()
                }
            }
        } else {
            
            if Session.sharedInstance.lite_canLoginUsingSessionToken() {
            updateViewStatus(ViewType.login, hidden: true)
            
            OperationQueue.main.addOperation {
                self.loginUsingRememberMe()
            }
            }
        }
    }
    
    func updateViewStatus(_ viewType: ViewType, hidden: Bool) {
        switch viewType {
        case .login:
            fieldEmail.isHidden           = hidden
            fieldPassword.isHidden        = hidden
            btnTakeOff.isHidden           = hidden
            btnCreateAccount.isHidden     = hidden
            btnForgotPassword.isHidden    = hidden
        default: assert(false, "Handle other view types")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(UserOnBoardViewController.keyboardWillAppear(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserOnBoardViewController.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserOnBoardViewController.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let bar = self.navigationController?.navigationBar as? ExtendedNavigationBar {
            bar.clearNavigationBar = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }

    func keyboardWillChangeFrame(_ n:Notification) {
        if fieldEmail.textfield.isEditing {
            scrollView.scrollRectToVisible(fieldEmail.frame, animated: true)
        } else if fieldFirstName.textfield.isEditing {
            scrollView.scrollRectToVisible(fieldFirstName.frame, animated: true)
        } else if fieldLastName.textfield.isEditing {
            scrollView.scrollRectToVisible(fieldLastName.frame, animated: true)
        } else if fieldPassword.textfield.isEditing {
            scrollView.scrollRectToVisible(fieldPassword.frame, animated: true)
        }
    }
    
    func keyboardWillAppear(_ notification:Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let value = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                let frame = value.cgRectValue
                scrollView.contentInset = UIEdgeInsetsMake(0, 0, frame.size.height, 0)
            }
        }
    }

    func keyboardWillDisappear(_ notification:Notification) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }

    fileprivate func createLoginConstraints() {
        if constraintsLoginView.count > 0 {
            return
        }

        let views = ["logo":containerLogo, "email":fieldEmail, "password":fieldPassword, "forgot":btnForgotPassword, "takeoff":btnTakeOff, "register":btnCreateAccount, "topGuide":topLayoutGuide] as [String:AnyObject]


        let vertical = VisualConstraint("V:|[logo(>=logoHeight)]-[email(==fHeight)]-[password(==fHeight)]-[forgot(==bHeight)]-[takeoff(==bHeight)]-[register(==bHeight)]|", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views)

        constraintsLoginView.append(contentsOf: vertical)

        for value in ["logo","email", "password", "takeoff"] {
            let horizontal = VisualConstraint("H:|-[\(value)]-|", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views)
            constraintsLoginView.append(contentsOf: horizontal)
        }

        for value in ["register"] {
            let horizontal = VisualConstraint("H:|[\(value)]|", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views)
            constraintsLoginView.append(contentsOf: horizontal)
        }


        do {
            let horizontal = VisualConstraint("H:[forgot]-|", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views)
            constraintsLoginView.append(contentsOf: horizontal)
        }
    }

    fileprivate func createRegisterConstraints() {
        if constraintsCreateAccount.count > 0 {
            return
        }

        let views = ["email":fieldEmail, "password":fieldPassword, "name":fieldFirstName,"lastname":fieldLastName, "takeoff":btnTakeOff] as [String : Any]

        let vertical = VisualConstraint("V:[name(==fHeight)]-[lastname(==fHeight)]-[email(==fHeight)]-[password(==fHeight)]-(>=20@200)-[takeoff(==bHeight)]", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views as [String : AnyObject])

        constraintsCreateAccount.append(contentsOf: vertical)
        
        for value in ["name","lastname", "email", "password", "takeoff"] {
            let horizontal = VisualConstraint("H:|-[\(value)]-|", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views as [String : AnyObject])
            constraintsCreateAccount.append(contentsOf: horizontal)
        }

    }

    fileprivate func setLoginVisibleViews() {

        viewType = .login
        fieldFirstName.isHidden = true
        fieldLastName.isHidden = true

        containerLogo.isHidden = false
        fieldEmail.isHidden = false
        fieldPassword.isHidden = false

        btnForgotPassword.isHidden = false
        btnTakeOff.isHidden = false
        btnCreateAccount.isHidden = false
        btnClose.isHidden = true

        btnTakeOff.setTitle(Consts.Title.BtnTakeOffLogin, for: UIControlState())
        
        fieldEmail.textfield.keyboardType = UIKeyboardType.emailAddress
        fieldEmail.textfield.returnKeyType = UIReturnKeyType.next
        fieldPassword.textfield.isSecureTextEntry = true
        fieldPassword.textfield.returnKeyType = UIReturnKeyType.go
        
//        allContainerView.userInteractionEnabled = true
    }

    fileprivate func setRegisterVisibleViews() {

        viewType = .register
        fieldFirstName.isHidden = false
        fieldLastName.isHidden = false
        btnClose.isHidden = false

        containerLogo.isHidden = true
        fieldEmail.isHidden = false
        fieldPassword.isHidden = false

        btnForgotPassword.isHidden = true
        btnTakeOff.isHidden = false
        btnCreateAccount.isHidden = true

        fieldFirstName.textfield.returnKeyType = UIReturnKeyType.next
        fieldLastName.textfield.returnKeyType = UIReturnKeyType.next

        fieldEmail.textfield.keyboardType = UIKeyboardType.emailAddress
        fieldEmail.textfield.returnKeyType = UIReturnKeyType.next

        fieldPassword.textfield.isSecureTextEntry = true
        fieldPassword.textfield.returnKeyType = UIReturnKeyType.go
        
        btnTakeOff.setTitle(Consts.Title.BtnTakeOffRegister, for: UIControlState())
//        allContainerView.userInteractionEnabled = true
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundImageView.frame = view.bounds
        scrollView.contentSize = allContainerView.bounds.size
    }

    fileprivate func createAllViews() {
        containerLogo = LogoContainerView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(logoViewTapped))
        containerLogo.isUserInteractionEnabled = true
        containerLogo.addGestureRecognizer(tapGesture)

        btnClose = UIButton()
        //TODO: Close btn should be switch to 'X'
        btnClose.setImage(UIImage(named: "ic_close_b")!.resize(CGSize(width: 25, height: 25)), for: UIControlState())
        btnClose.addTarget(self, action: #selector(UserOnBoardViewController.closeRegister), for: UIControlEvents.touchUpInside)

        fieldFirstName = SeparatedTextfield(placeholder: Consts.Title.FieldFirstName, image:UIImage(named: Consts.Image.FieldName)!,  themeColor: Consts.Colors.FieldTheme, delegate:self)
        fieldLastName = SeparatedTextfield(placeholder: Consts.Title.FieldLastName, image:UIImage(named: Consts.Image.FieldName)!,  themeColor: Consts.Colors.FieldTheme, delegate:self)
        fieldEmail = SeparatedTextfield(placeholder: Consts.Title.FieldEmail,image:UIImage(named: Consts.Image.FieldEmail)!, themeColor: Consts.Colors.FieldTheme, delegate:self)
        fieldEmail.textfield.keyboardType = UIKeyboardType.emailAddress
        fieldEmail.textfield.autocorrectionType = UITextAutocorrectionType.no
        fieldEmail.textfield.autocapitalizationType = UITextAutocapitalizationType.none
        fieldPassword = SeparatedTextfield(placeholder: Consts.Title.FieldPassword,image:UIImage(named: Consts.Image.FieldPassword)!, themeColor: Consts.Colors.FieldTheme, delegate:self)

        btnForgotPassword = btn(Consts.Title.BtnForgotPassword, primary:true)
        btnForgotPassword.backgroundColor = Consts.Colors.BtnForgotPasswordBackground
        btnForgotPassword.setTitleColor(Theme.secondary.buttonTextColor(UIControlState()), for: UIControlState())
        btnForgotPassword.addTarget(self, action: #selector(UserOnBoardViewController.forgotPasswordBtnTapped(_:)), for: UIControlEvents.touchUpInside)

        btnTakeOff = btn(Consts.Title.BtnTakeOffLogin, primary:true)
        btnTakeOff.addTarget(self, action: #selector(UserOnBoardViewController.takeOffBtnTapped(_:)), for: UIControlEvents.touchUpInside)

        btnCreateAccount = UIButton()
        btnCreateAccount.setTitle(Consts.Title.BtnRegister, for: UIControlState())
        btnCreateAccount.setTitleColor(Consts.Colors.BtnRegisterTitle, for: UIControlState())
        btnCreateAccount.backgroundColor = Consts.Colors.BtnRegisterBackground
        btnCreateAccount.addTarget(self, action: #selector(UserOnBoardViewController.displayRegister), for: UIControlEvents.touchUpInside)

        for x in [containerLogo, btnCreateAccount, fieldEmail, fieldPassword, btnForgotPassword, btnTakeOff, fieldFirstName, fieldLastName, btnClose] as [Any] {
            (x as! UIView).translatesAutoresizingMaskIntoConstraints = false
            allContainerView.addSubview(x as! UIView)
        }

        #if (DEBUG)
            if AppConstants.IsSimulator {
                fieldEmail.text = "chuthan20@gmail.com"
                fieldPassword.text = "archuthan"
            }
        #endif
    }

    func logoViewTapped(_ sender: UITapGestureRecognizer) {
        _ = self.request?.cancel()
    }
    
    func closeRegister() {
        
        view.endEditing(true)
//        self.removeErrorBanner()
        self.removeErrorView(true)
        createLoginConstraints()
        setLoginVisibleViews()

        NSLayoutConstraint.deactivate(self.constraintsTransition)
        NSLayoutConstraint.deactivate(self.constraintsForgotPassword)
        NSLayoutConstraint.deactivate(self.constraintsCreateAccount)
        NSLayoutConstraint.activate(self.constraintsLoginView)

        UIView.animateKeyframes(withDuration: animDuration, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {

            // move
            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 1, animations: {
                self.view.layoutIfNeeded()
            })

            UIView.addKeyframe(withRelativeStartTime: 0.99, relativeDuration: 0.05, animations: {
                self.btnForgotPassword.alpha = 1
            })

            }, completion: { (finish) in
        })
    }
    
    func removeErrorView(_ animated:Bool) {
        
        UIView.animate(withDuration: animated ? 0.1 : 0.0, animations: { () -> Void in
            self.errorView.frame = CGRect(x: 0, y: -60, width: self.view.frame.width, height: 30)
            }, completion: { (finished) -> Void in
                if (finished) {
                    self.errorView.removeFromSuperview()
                    self.errorView.subviews.forEach { (v) -> () in
                        v.removeFromSuperview()
                    }
                }
        }) 
    }
    
    func displayErrorView(_ message:String, animated:Bool) {

        errorView = UIView()
        errorView.backgroundColor = UIColor.red
        
        let label = UILabel()
        label.text = message
        label.textAlignment = NSTextAlignment.center
        label.sizeToFit()
        label.textColor = UIColor.white
        errorView.addSubview(label)
        if errorView.superview == nil {
            view.addSubview(errorView)
            
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        do {
            let cons = EqualConstraints(label, errorView, [.centerX, .centerY, .leading, .trailing, .top])
            view.addConstraints(cons)
        }
        self.errorView.frame = CGRect(x: 0, y: -60, width: self.view.frame.width, height: 30)
        self.errorView.layoutIfNeeded()
        UIView.animate(withDuration: animated ? 0.1 : 0.0, animations: { () -> Void in
            self.errorView.frame = CGRect(x: 0, y: 60, width: self.view.frame.width, height: 30)
        }) 
    }
    
    func displayRegister() {
//        self.removeErrorBanner()
        self.view.endEditing(true)
        self.removeErrorView(false)

        createRegisterConstraints()

        let views = ["email":fieldEmail, "password":fieldPassword, "name":fieldFirstName,"lastname":fieldLastName, "takeoff":btnTakeOff, "register":btnCreateAccount, "logo":containerLogo, "forgot":btnForgotPassword, "close":btnClose, "topGuide":topLayoutGuide] as [String:AnyObject]


        constraintsTransition.removeAll()

        constraintsTransition.append(contentsOf: VisualConstraint("H:|-[logo(==logoHeight)]-|", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views))
        constraintsTransition.append(contentsOf: VisualConstraint("H:|-[register(==fHeight)]-|", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views))

        constraintsCreateAccount.append(contentsOf: VisualConstraint("H:|-[close]", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views))

        do {
            let cons = VisualConstraint("V:[topGuide]-2@20-[close]", options: autoLayoutFormatOptions, metrics: autoLayoutMetrics as [String : AnyObject]?, views: views)
            constraintsCreateAccount.append(contentsOf: cons)
        }

        //hide logo to top
        constraintsTransition.append(NSLayoutConstraint(item: containerLogo, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: -view.frame.size.height))


        // center the textfield to view
        do {
            let cons = NSLayoutConstraint(item: fieldEmail, attribute: .centerY, relatedBy: .equal, toItem: allContainerView, attribute: .centerY, multiplier: 1, constant: 0)
            constraintsTransition.append(cons)
        }

        fieldFirstName.isHidden = true
        fieldFirstName.alpha = 0
        fieldLastName.isHidden = true
        fieldLastName.alpha = 0

        UIView.animateKeyframes(withDuration: animDuration, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {

            // move
            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 1, animations: {
                NSLayoutConstraint.deactivate(self.constraintsLoginView)
                NSLayoutConstraint.activate(self.constraintsCreateAccount)
                NSLayoutConstraint.activate(self.constraintsTransition)
                self.view.layoutIfNeeded()

            })

            UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.1, animations: {
                self.btnForgotPassword.alpha = 0
                self.btnClose.isHidden = false
            })

            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1, animations: {
                self.fieldFirstName.isHidden = false
                self.fieldFirstName.alpha = 1
                self.fieldLastName.isHidden = false
                self.fieldLastName.alpha = 1
            })

            }, completion: { (finish) in
                self.setRegisterVisibleViews()
        })
        
    }

    func forgotPasswordBtnTapped(_ sender: UIButton) {
        self.removeErrorView(true)
        if let vc = storyboard?.instantiateViewController(withIdentifier: "forgotpassword") as? ForgotPasswordViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func takeOffBtnTapped(_ sender: UIButton) {
        self.removeErrorView(false)
        switch viewType {
        case .login:
            login(tries: 0)
        case .register:
            registerAccount()
        case .forgotPassword:
            do {
                abort()
            }
        }
    }

    //MARK: Network Calls
    func login(tries:Int) {
        
        Session.sharedInstance.clearLoginSessionToken()
        
        guard tries < 2 else {
            OperationQueue.main.addOperation { [weak self] in
                self?.animateLogoLoading = false
//                self?.allContainerView.userInteractionEnabled = true
//                self?.allContainerView.userInteractionEnabled = true
            }
            return
        }

        if let email = fieldEmail.textfield.text, let password = fieldPassword.textfield.text {
            self.view.endEditing(true)
            animateLogoLoading = true

            let waitDuration = 0.50
            let when = DispatchTime.now() + Double(Int64(waitDuration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

            DispatchQueue.main.asyncAfter(deadline: when, execute: { [weak self] in

                self?.request = SessionRequest.login(email: email, password: password, rememberMe: true, fetchJWT: true, completion: { (user, error) -> Void in
                    OperationQueue.main.addOperation {
                        self?.handleLoginResponse(tries, user: user, error: error)
                    }
                }).execute()
            })
        }
    }

    fileprivate func loginSucceeded(_ user: User?) {
        NSLog("Logged in with user with id: \(user?.identifier)");
        NSLog("User's device ID: \(Utilities.flybitsDeviceID)");
        NSLog("User's JWT: \(Session.sharedInstance.jwt)");
        self.delegate?.userOnBoard(self, result: .success, viewType: .login)
    }
    
    fileprivate func handleLoginResponse(_ tries:Int, user:User?, error:NSError?) {
        if Utils.ErrorChecker.noInternetConnection(error) {
            self.displayErrorView("ERROR_NO_INTERNET_CONNECTION".lite_localized(), animated:true)
            
        } else if user != nil && error == nil {
            loginSucceeded(user)
            
        } else {
            if Utils.ErrorChecker.noInternetConnection(error) {
                self.displayErrorView("ERROR_NO_INTERNET_CONNECTION".lite_localized(), animated:true)
            } else if let error = error , Utils.ErrorChecker.isExceptionType("OnlyAvailableToGuestsException", error: error) {
                self.request = SessionRequest.logout { (success, error) -> Void in
                    OperationQueue.main.addOperation {
                        self.login(tries: tries + 1)
                    }
                }.execute()
                return
            } else if let userInfo = error?.userInfo[NSLocalizedDescriptionKey] as? [String:AnyObject] {
                if let str = userInfo["exceptionMessage"] as? String {
                    if let userInfo = userInfo["details"] as? [String:AnyObject] {
                        self.displayErrorFields(userInfo)
                    }
                    self.displayErrorView(str, animated:true)
                } else if let str = userInfo["message"] as? String {
                    self.displayErrorView(str, animated:true)
                }
            } else if let userInfo = error?.userInfo["details"] as? [String:AnyObject] {
                self.displayErrorFields(userInfo)
            } else if let message = error?.localizedDescription {
                self.displayErrorView(message, animated:true)
            }
        }
        self.containerLogo.isUserInteractionEnabled = true
//        self.allContainerView.userInteractionEnabled = true
        
        self.animateLogoLoading = false
    }
    
    fileprivate func loginUsingRememberMe() {
        
//        self.allContainerView.userInteractionEnabled = false
        self.animateLogoLoading = true
        
        _ = Session.sharedInstance.reconnectSession { [weak self] (valid, currentUser, error) -> Void in
            OperationQueue.main.addOperation {
                if let tempSelf = self , valid || currentUser != nil {
                    tempSelf.loginSucceeded(currentUser)
                } else {
                    if let err = error, let flybitsError = Utils.ErrorChecker.FlybitsError(err) {
                        self?.displayErrorView(flybitsError.exceptionMessage ?? flybitsError.exceptionType, animated:true)
                    } else {
                        if error?.domain == NSURLErrorDomain && error?.code == NSURLErrorNotConnectedToInternet {
                            self?.displayErrorView("ERROR_NO_INTERNET_CONNECTION".lite_localized(), animated:true)
                        } else {
                            Session.sharedInstance.clearLoginSessionToken()
                            self?.displayErrorView("ERROR_UNABLE_TO_LOGIN".lite_localized(), animated:true)
                        }
                    }
                }
//                self?.allContainerView.userInteractionEnabled = true
                self?.animateLogoLoading = false
                self?.updateViewStatus(ViewType.login, hidden: false)
            }
        }
    }

    fileprivate func registerAccount() {
        fieldEmail.removeErrorView()
        fieldPassword.removeErrorView()
        fieldFirstName.removeErrorView()
        fieldLastName.removeErrorView()
        
        guard let name = fieldFirstName.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) , name.characters.count > 1 else {
            self.displayErrorView("USERONBOARD_REGISTRATION_MISSING_FIELD_FIRSTNAME".lite_localized(), animated:true)
            fieldFirstName.displayErrorView()
            return
        }
        guard let lastname = fieldLastName.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) , lastname.characters.count > 1 else {
            self.displayErrorView("USERONBOARD_REGISTRATION_MISSING_FIELD_LASTNAME".lite_localized(), animated:true)
            fieldLastName.displayErrorView()
            return
        }
        guard let email = fieldEmail.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            self.displayErrorView("USERONBOARD_REGISTRATION_MISSING_FIELD_EMAIL".lite_localized(), animated:true)
            fieldEmail.displayErrorView()
            return
        }
        guard let password = fieldPassword.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            self.displayErrorView("USERONBOARD_REGISTRATION_MISSING_FIELD_PASSWORD".lite_localized(), animated:true)
            fieldPassword.displayErrorView()
            return
        }
        
        self.view.endEditing(true)
        
        let query = AccountQuery()
        query.firstname = name
        query.lastname = lastname
        query.email = email
        query.password = password
        
        let dimmedLoadingView = LoadingView(frame: self.view.frame)
        self.view.addSubview(dimmedLoadingView)
        dimmedLoadingView.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        /*
        1. Register
            - on success
                1. Logout
                    - on success
                        Login with credentials that they used to register (so push, rememberMe token & other things gets initialized properly)
                            - on success
                                Take them to home page
                            - on fail
                                Notify registration is success but unable to login
                    - on fail
                        Notify registration is success -- and take them to login page
            - on fail
                1. Notify registeration failed
        */
        _ = AccountRequest.register(query, completion: { [weak self](user, error) -> Void in
            if let _ = user {
                //TODO: Should just display "Success, activate the email"?
                self?.request = SessionRequest.logout(completion: { [weak self](success, error) -> Void in
                    if success {
                        OperationQueue.main.addOperation({
                            
                            let alert = UIAlertController(title: "USERONBOARD_REGISTERATION_SUCCEEDED".lite_localized(), message: "", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "ALERT_OK".lite_localized(), style: UIAlertActionStyle.cancel, handler: { (action) -> Void in
                                
                                self?.request = SessionRequest.login(email: email, password: password, rememberMe: true, fetchJWT: true, completion: { [weak self](user, error) -> Void in
                                    OperationQueue.main.addOperation {
                                        if user != nil && error == nil {
                                            self?.handleLoginResponse(0, user: user, error: error)
                                            dimmedLoadingView.removeFromSuperview()
                                        } else {
                                            let alert = UIAlertController(title: "USERONBOARD_REGISTERATION_SUCCEEDED_LOGIN_FAILED".lite_localized(), message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                                            alert.addAction(UIAlertAction(title: "ALERT_OK".lite_localized(), style: UIAlertActionStyle.cancel, handler: { [weak self](action) -> Void in
                                                self?.closeRegister()
                                            }))
                                            self?.present(alert, animated: true, completion: nil)
                                            dimmedLoadingView.removeFromSuperview()
                                        }
                                    }
                                }).execute()
                            }))
                            self?.present(alert, animated: true, completion: nil)
                            dimmedLoadingView.removeFromSuperview()
                        })
                    } else {
                        OperationQueue.main.addOperation({
                            let alert = UIAlertController(title: "USERONBOARD_REGISTERATION_SUCCEEDED".lite_localized(), message: "", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "ALERT_OK".lite_localized(), style: UIAlertActionStyle.cancel, handler: { [weak self](action) -> Void in
                                self?.closeRegister()
                            }))
                            self?.present(alert, animated: true, completion: nil)
                            dimmedLoadingView.removeFromSuperview()
                        })
                    }
                }).execute()
                
            } else if let error = error {
                let convertedError = Utils.ErrorChecker.formatError(error)
                OperationQueue.main.addOperation({
                    self?.displayErrorView(convertedError.localizedDescription, animated:true)
                    if let details = convertedError.userInfo[Const.FBSDK.ExceptionKey.Details] as? [String:AnyObject] {
                        self?.displayErrorFields(details)
                    }
                    dimmedLoadingView.removeFromSuperview()
                })
            } else if let dict = error?.userInfo["details"] as? [String:AnyObject] {
                OperationQueue.main.addOperation({
                    self?.displayErrorFields(dict)
                    dimmedLoadingView.removeFromSuperview()
                })
            } else if let userInfo = error?.userInfo[NSLocalizedDescriptionKey] as? NSData,
                let json = try? JSONSerialization.jsonObject(with: userInfo as Data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject],
                let jsonObj = json,
                let dict = jsonObj["details"] as? [String:AnyObject] {
                    
                    OperationQueue.main.addOperation({
                        self?.displayErrorFields(dict)
                        dimmedLoadingView.removeFromSuperview()
                    })
            } else {
                OperationQueue.main.addOperation({
                    let str:String = error?.localizedDescription ?? "USERONBOARD_REGISTERATION_FAILED".lite_localized()
                    self?.displayErrorView(str, animated:true)
                    dimmedLoadingView.removeFromSuperview()
                })
            }
        }).execute()
    }
    
    fileprivate func displayErrorFields(_ dict:[String:AnyObject]) {
        if let arr = dict["email"] as? [String] , arr.first != nil {
            self.displayErrorView(arr.first!, animated:true)
            self.fieldEmail.displayErrorView()
        } else if let arr = dict["password"] as? [String] , arr.first != nil {
            self.displayErrorView(arr.first!, animated:true)
            self.fieldPassword.displayErrorView()
        } else if let arr = dict["firstname"] as? [String] , arr.first != nil {
            self.displayErrorView(arr.first!, animated:true)
            self.fieldFirstName.displayErrorView()
        } else if let arr = dict["lastname"] as? [String] , arr.first != nil {
            self.displayErrorView(arr.first!, animated:true)
            self.fieldLastName.displayErrorView()
        } else if let message = dict["message"] as? String {
            self.displayErrorView(message, animated:true)
        }
    }
    

    //UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        switch viewType {
        case .login:
            if textField == fieldEmail.textfield {
                if let email = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces) , !email.contains("@") {
                    fieldEmail.text = email + "@flybits.com"
                }
                fieldPassword.textfield.becomeFirstResponder()
                return false
            } else if textField == fieldPassword.textfield {
                fieldPassword.textfield.resignFirstResponder()
                login(tries: 0)
                return true
            }
        case .register:
            switch textField {
            case fieldFirstName.textfield:
                fieldLastName.textfield.becomeFirstResponder()
                return false
            case fieldLastName.textfield:
                fieldEmail.textfield.becomeFirstResponder()
                return false
            case fieldEmail.textfield:
                fieldPassword.textfield.becomeFirstResponder()
                return false
            case fieldPassword.textfield:
                fieldPassword.textfield.resignFirstResponder()
                registerAccount()
                return true
            default:
                // UNREGISTERED TEXTFIELD?
                abort()
            }
            

        case .forgotPassword:
            return true
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {

        switch viewType {
        case .login:
            if textField == fieldEmail.textfield {
                fieldEmail.removeErrorView()
            } else if textField == fieldPassword.textfield {
                fieldPassword.removeErrorView()
            }
        case .register:
            if textField == fieldFirstName.textfield {
                fieldFirstName.removeErrorView()
            } else if textField == fieldLastName.textfield {
                fieldLastName.removeErrorView()
            } else if textField == fieldEmail.textfield {
                fieldEmail.removeErrorView()
            } else if textField == fieldPassword.textfield {
                fieldPassword.removeErrorView()
            }
        case .forgotPassword:
            do {
                abort()
            }
        }
//        self.removeErrorBanner()
        self.removeErrorView(true)
    }
}

func btn(_ title:String, primary:Bool) -> ThemedButton {
    let btn = ThemedButton()
    btn.setTitle(title, for: UIControlState())
    btn.primaryTheme = primary
    return btn
}



private struct Consts {
    struct Title {
        static let FieldFirstName = "Firstname"
        static let FieldLastName = "Lastname"
        static let FieldEmail = "Email"
        static let FieldPassword = "Password"

        static let BtnForgotPassword = "Forgot Password?"
        static let BtnLoginWithFacebook = "Login with Facebook"

        static let BtnTakeOffLogin = "TAKEOFF"
        static let BtnTakeOffRegister = "TAKEOFF"
        static let BtnRegister = "Create Account"
    }

    struct Image {
        static let FieldName = "ic_surname_g"
        static let FieldEmail = "ic_email_g"
        static let FieldPassword = "ic_password_g"
    }

    struct Colors {
        static let ViewBackground = UIColor.white
        static let FieldTheme = UIColor.gray
        static let BtnRegisterTitle = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        static let BtnRegisterBackground = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        static let BtnForgotPasswordBackground = UIColor.clear

    }
}


class LogoContainerView : UIView {

    var imageView: UIImageView!
    var versionLabel: UILabel!

    var animateLoading: Bool = false {
        didSet {
            if animateLoading {
                imageView.animationImages = AppConstants.UI.LoadingAnimationImages
                imageView.animationDuration = 2
                imageView.startAnimating()
            } else {
                imageView.image = AppConstants.UI.UserOnBoardLogoImage
                imageView.stopAnimating()
                imageView.animationImages = nil
            }
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        let image = UIImageView(image: AppConstants.UI.UserOnBoardLogoImage)
        imageView = image
        addSubview(image)
        image.contentMode = UIViewContentMode.scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false

        versionLabel = UILabel()
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.font = UIFont.systemFont(ofSize: 10)
        versionLabel.text = Utils.buildVersionString()
        versionLabel.textAlignment = NSTextAlignment.center
        versionLabel.textColor = UIColor.blue
        addSubview(versionLabel)
        
        let views = ["image": imageView, "version": versionLabel] as [String : Any]

        addConstraints(VisualConstraint("H:[image(<=120,>=70)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views as [String : AnyObject]))
        addConstraints(VisualConstraint("V:[image(<=120,>=70)][version(==20)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views as [String : AnyObject]))
        addConstraints(VisualConstraint("H:|[version]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views as [String : AnyObject]))

        addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        //        buildVersionString()
    }
    
    
}

// MARK - TouchID

extension UserOnBoardViewController {
    fileprivate func isTouchIDAvailable() -> Bool {
        // test if we can evaluate the policy, this test will tell us if Touch ID is available and enrolled
        return LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    fileprivate func populateLoginFieldsUsingTouchID(_ completion:@escaping (_ success:Bool, _ error:NSError?) -> Void) {
        
        let context = LAContext()
        context.localizedFallbackTitle = "USERONBOARD_TOUCH_ID_ALERT_TITLE".lite_localized()
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "USERONBOARD_TOUCH_ID_ALERT_BODY".lite_localized()) { (success, error) -> Void in
            completion(success, error as NSError?)
        }
    }
}


// MARK - NSLayoutConstraint -- convenience

private func EqualConstraints(_ view1:UIView, _ parentView:UIView, _ attributes:[NSLayoutAttribute]) -> [NSLayoutConstraint] {
    var results = [NSLayoutConstraint]()
    for x in attributes {
        results.append(EqualConstraint(view1, parentView, x))
    }
    return results
}

private func EqualConstraint(_ view1:UIView, _ parentView:UIView, _ attribute:NSLayoutAttribute) -> NSLayoutConstraint {
    return NSLayoutConstraint(item: view1, attribute: attribute, relatedBy: .equal, toItem: parentView, attribute: attribute, multiplier: 1, constant: 0)
}

private func VisualConstraint(_ format:String, options:NSLayoutFormatOptions = NSLayoutFormatOptions(rawValue: 0), metrics:[String : AnyObject]? = nil, views:[String:AnyObject]) -> [NSLayoutConstraint] {
    let cons = NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: metrics, views: views)
    for x in cons {
        x.identifier = nameFromVisualConstraintObjects(x.firstItem as? NSObject, views: views) + " - " + nameFromVisualConstraintObjects(x.secondItem as? NSObject, views: views)
    }
    return cons
}

private func nameFromVisualConstraintObjects(_ obj:NSObject?, views:[String:AnyObject]) -> String {

    let newViews = views as! [String:NSObject]
    for (x, y) in newViews where y == obj {
        return x
    }
    return " (parent?) "
}

extension Session {
    func lite_canLoginUsingSessionToken() -> Bool {
        return self.canLoginUsingSessionToken()
    }
}
