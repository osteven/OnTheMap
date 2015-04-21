//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/15/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: -
    // MARK: properties
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    private let netClient = NetClient()
    private let currentUser = (UIApplication.sharedApplication().delegate as! AppDelegate).currentUser



    // MARK: -
    // MARK: loading

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
    }


    func configureUI() {
        /* Configure background gradient */
        self.view.backgroundColor = UIColor.clearColor()
        let colorTop = UIColor(red: 0.984, green: 0.605, blue: 0.168, alpha: 1.0).CGColor
        let colorBottom = UIColor(red: 0.984, green: 0.438, blue: 0.129, alpha: 1.0).CGColor
        var backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [colorTop, colorBottom]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.frame = self.view.frame
        self.view.layer.insertSublayer(backgroundGradient, atIndex: 0)


        // spacing from here: http://stackoverflow.com/questions/7565645/indent-the-text-in-a-uitextfield
        let loginSpacer = UIView(frame: CGRectMake(0, 0, 10, 10))
        loginTextField.leftViewMode = .Always
        loginTextField.leftView = loginSpacer
        let passSpacer = UIView(frame: CGRectMake(0, 0, 10, 10))
        passwordTextField.leftViewMode = .Always
        passwordTextField.leftView = passSpacer

        loginTextField.delegate = self
        passwordTextField.delegate = self

        loginTextField.alpha = 0.6
        passwordTextField.alpha = 0.6

        manageLoginButton(false)
    }

    
    // MARK: -
    // MARK: login-related functions

    @IBAction func doLogin() {
        if let userName = loginTextField.text, let password = passwordTextField.text {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            manageUI(false)
            netClient.loadSessionIDAndUserKey(userName, password: password, completionHandler: sessionAndUserKeyClosure)
        }
    }

    private func loadPublicUserData() {
        netClient.loadPublicUserData(self.currentUser.userKey!, completionHandler: publicUserDataClosure)
    }

    @IBAction func udacitySignUp() {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://www.udacity.com/account/auth#!/signup")!)
    }

    private func errorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }


    // MARK: -
    // MARK: login-related closures

    /*
    Error Domain=NSURLErrorDomain Code=-1001 "The request timed out." UserInfo=0x7b70f6e0 {NSErrorFailingURLStringKey=https://www.udacity.com/api/session, NSErrorFailingURLKey=https://www.udacity.com/api/session, NSLocalizedDescription=The request timed out., NSUnderlyingError=0x7bac4b10 "The operation couldn’t be completed. (kCFErrorDomainCFNetwork error -1001.)"}
    */


    func sessionAndUserKeyClosure(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        dispatch_async(dispatch_get_main_queue(), { self.manageUI(true) })
        if error != nil {
            errorAlert("Connection Failure", message: "Failed to connect to Udacity\n\n[\(error.localizedDescription)]")
            return
        }

        let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))  /* subset response data! */
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let error = parseError {
            errorAlert("Connection Failure", message: "Incomplete data from Udacity\n\n[\(error.localizedDescription)]")
            return
        }

        if let accountDict = topDict!["account"] as? NSDictionary, let sessionDict = topDict!["session"] as? NSDictionary {
            self.currentUser.userKey = accountDict["key"] as? String
            self.currentUser.sessionID = sessionDict["id"] as? String
            dispatch_async(dispatch_get_main_queue(), { self.loadPublicUserData() })
        } else if let status = topDict!["status"] as? Int, let errorStr = topDict!["error"] as? NSString {
            // else, found an error message in the response
            errorAlert("Login Failure", message: "The email or password you \nentered is invalid\n\n[\(status):\(errorStr)]")
        }
    }


    func publicUserDataClosure(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void {
        if error != nil { // Handle error...
            println("Failed to get Udacity public user data: \(error)")
            return
        }
        let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* subset response data! */
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let error = parseError {
            println("Failed to parse Udacity data: \(error)")
        } else {
            if let userDict = topDict!["user"] as? NSDictionary {
                self.currentUser.lastName = userDict["last_name"] as? String
                self.currentUser.firstName = userDict["first_name"] as? String
                if let emailDict = userDict["email"] as? NSDictionary {
                    self.currentUser.email = emailDict["address"] as? String
                }

                // http://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift
                let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
                dispatch_async(backgroundQueue, { self.netClient.loadStudentLocations(self.studentLocationClosure) })

                dispatch_async(dispatch_get_main_queue(), {
                    let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MapAndListTabController") as! UITabBarController
                    self.presentViewController(controller, animated: true, completion: nil)
                })

            }
        }
    }

    func studentLocationClosure(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void {
        if error != nil { // Handle error...
            println("Failed to get Parse API student location data: \(error)")
            return
        }
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let error = parseError {
            println("Failed to parse Parse data: \(error)")
        } else {
            if let userDict = topDict!["results"] as? [[String: AnyObject]] {
                StudentManager.sharedInstance.load(userDict)
            } else {
                println("Failed to find user dictionary")
            }
        }
    }


    // MARK: -
    // MARK: text field and login button management

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }


    /*
    Assume that Udacity email and password must be at least four characters and that login 
    has '@' and '.'
    I did a minimal amount of validation here because it's really hard to validate email addresses 
    and it's not in the spec to do so.
    http://stackoverflow.com/questions/201323/using-a-regular-expression-to-validate-an-email-address?rq=1
    */
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {

        var enableLogin: Bool = false
        var newPasswordText: NSString = passwordTextField.text
        var newLoginText: NSString = loginTextField.text

        if textField == loginTextField {
            newLoginText = newLoginText.stringByReplacingCharactersInRange(range, withString: string)
        } else {
            newPasswordText = newPasswordText.stringByReplacingCharactersInRange(range, withString: string)
        }
        enableLogin = (newLoginText.length >= 4) && (newPasswordText.length >= 4)
        if enableLogin {
            enableLogin = (newLoginText.rangeOfString(".").location != NSNotFound) && (newLoginText.rangeOfString("@").location != NSNotFound)
        }
        manageLoginButton(enableLogin)
        return true
    }

    private func manageUI(enable: Bool) {
        if !enable {
            loginTextField.resignFirstResponder()
            passwordTextField.resignFirstResponder()
            loginTextField.alpha = 0.2
            passwordTextField.alpha = 0.2
        } else {
            loginTextField.alpha = 0.6
            passwordTextField.alpha = 0.6
        }
        loginTextField.enabled = enable
        passwordTextField.enabled = enable
        manageLoginButton(enable)
    }

    private func manageLoginButton(enable: Bool) {
        loginButton.enabled = enable
        if enable {loginButton.alpha = 1.0 } else { loginButton.alpha = 0.2 }
    }


}

