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
    @IBOutlet weak var loginContainerView: UIView!

    private let currentUser = (UIApplication.sharedApplication().delegate as! AppDelegate).currentUser
    private var errorMessage = ""


    // MARK: -
    // MARK: loading

    override func viewDidLoad() {
        super.viewDidLoad()

        UICommon.setGradientForView(self.view)
        UICommon.setUpSpacerForTextField(loginTextField)
        UICommon.setUpSpacerForTextField(passwordTextField)

        loginTextField.delegate = self
        passwordTextField.delegate = self
        manageLoginButton(false)
}




    // MARK: -
    // MARK: login-related functions & closures

    @IBAction func doLogin() {
        if let userName = loginTextField.text, let password = passwordTextField.text {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            manageUI(false)
            NetClient.sharedInstance.loadSessionIDAndUserKey(userName, password: password, completionHandler: sessionAndUserKeyClosure)
        }
    }

    @IBAction func udacitySignUp() {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://www.udacity.com/account/auth#!/signup")!)
    }

    /*
        First, restore the UI.  Next, check for Connection Failure.  Third, try to parse the 
        data and report error if it fails.  Fourth, grab the user key and session ID from 
        the parsed data or report a bad login.  Finally, ask the NetClient to request the 
        user data from the Udacity API, passing in the next closure.
    */
    func sessionAndUserKeyClosure(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if error != nil {
            dispatch_async(dispatch_get_main_queue(), { self.manageUI(true) })
            UICommon.errorAlert("Connection Failure", message: "Failed to connect to Udacity\n\n[\(error.localizedDescription)]", inViewController: self)
            return
        }

        let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))  /* subset response data! */
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let err = parseError {
            dispatch_async(dispatch_get_main_queue(), { self.manageUI(true) })
            UICommon.errorAlert("Parse Failure", message: "Could not parse account data from Udacity\n\n[\(err.localizedDescription)]", inViewController: self)
            return
        }

        if let accountDict = topDict!["account"] as? NSDictionary, let sessionDict = topDict!["session"] as? NSDictionary {
            if let userKey = accountDict["key"] as? String {
                self.currentUser.userKey = userKey
                if let sess = sessionDict["id"] as? String { self.currentUser.sessionID = sess }
                NetClient.sharedInstance.loadPublicUserData(userKey, completionHandler: publicUserDataClosure)
            } else {
                dispatch_async(dispatch_get_main_queue(), { self.manageUI(true) })
                UICommon.errorAlert("Udacity Login Failure", message: "The Udacity API failed to return a User Key", inViewController: self)
            }
        } else if let status = topDict!["status"] as? Int, let errorStr = topDict!["error"] as? NSString {
            // else, found an error message in the response
            self.errorMessage = "The email or password you \nentered is invalid\n\n[\(status):\(errorStr)]"
            dispatch_async(dispatch_get_main_queue(), { self.reportLoginFailureWithShake() })
            dispatch_async(dispatch_get_main_queue(), { self.manageUI(true) })
        }
    }

    //http://stackoverflow.com/questions/3844557/uiview-shake-animation
    private func reportLoginFailureWithShake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.delegate = self
        animation.duration = 0.10
        animation.repeatCount = 6
        animation.autoreverses = true

        let fromPoint = CGPointMake(loginContainerView.center.x - 20.0, loginContainerView.center.y)
        animation.fromValue = NSValue(CGPoint: fromPoint)

        let toPoint = CGPointMake(loginContainerView.center.x + 20.0, loginContainerView.center.y)
        animation.toValue = NSValue(CGPoint: toPoint)

        loginContainerView.layer.addAnimation(animation, forKey: "position")
    }

    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        UICommon.errorAlert("Login Failure", message: self.errorMessage, inViewController: self)
    }

    /*
        First, check for Connection Failure.  Next, try to parse the data and report error 
        if it fails. Third, grab the user name and email from the parsed data.  Next, 
        initiate a NetClient background queue request for the location list, passing in 
        the next closure.  Finally load the Map/List controller in the main queue.
    */
    func publicUserDataClosure(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void {
        if error != nil {
            UICommon.errorAlert("Connection Failure", message: "Failed to get Udacity public user data\n\n[\(error.localizedDescription)]", inViewController: self)
            return
        }
        let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* subset response data! */
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let err = parseError {
            UICommon.errorAlert("Parse Failure", message: "Could not parse user data from Udacity\n\n[\(err.localizedDescription)]", inViewController: self)
            return
        }

        if let userDict = topDict!["user"] as? [String: AnyObject] {

            self.currentUser.loadPublicData(userDict)
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MapAndListTabController") as! MapListViewController

            /* 
                Use a background queue to query the Parse API.  It queries both the total count 
                of all Student Locations, the first 100 Student Locations.  At the same time 
                on the main queue, load the Map & List tab controller.  Here is how I learned 
                to use background queues:
                http://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift
            */

            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { NetClient.sharedInstance.loadStudentLocations(controller.studentLocationClosure) })

            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(controller, animated: true, completion: nil)
            })

        } else {
            UICommon.errorAlert("Connection Failure", message: "Incomplete data from Udacity\n\n[\(error.localizedDescription)]", inViewController: self)
        }
    }


    // MARK: -
    // MARK: text field and login button management

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if count(loginTextField.text) > 0 && count(passwordTextField.text) > 0 {
            textField.resignFirstResponder()
            dispatch_async(dispatch_get_main_queue(), { self.doLogin() })
            return true
        }
        if textField == loginTextField { passwordTextField.becomeFirstResponder() }
        return true
    }


    /*
    Assume that Udacity email and password must be at least four characters and that login
    has '@' and '.'  I did a minimal amount of validation here because it's really hard to 
    validate email addresses and it's not in the spec to do so.
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

