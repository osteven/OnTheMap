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

    private let currentUser = (UIApplication.sharedApplication().delegate as! AppDelegate).currentUser



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
        First, restore the UI.  Next, check for Connection Failure.  Third, try to parse the data and
        report error if it fails.  Fourth, grab the user key and session ID from the parsed data or 
        report a bad login.  Finally, ask the NetClient to request the user data from the Udacity API,
        passing in the next closure.
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
            self.currentUser.userKey = accountDict["key"] as? String
            self.currentUser.sessionID = sessionDict["id"] as? String
            NetClient.sharedInstance.loadPublicUserData(self.currentUser.userKey!, completionHandler: publicUserDataClosure)
        } else if let status = topDict!["status"] as? Int, let errorStr = topDict!["error"] as? NSString {
            // else, found an error message in the response
            dispatch_async(dispatch_get_main_queue(), { self.manageUI(true) })
            UICommon.errorAlert("Login Failure", message: "The email or password you \nentered is invalid\n\n[\(status):\(errorStr)]", inViewController: self)
        }
    }

    /*
        First, check for Connection Failure.  Next, try to parse the data and report error if it fails.  
        Third, grab the user name and email from the parsed data.  Next, initiate a NetClient background
        queue request for the location list, passing in the next closure.  Finally load the Map/List 
        controller in the main queue.
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

        if let userDict = topDict!["user"] as? NSDictionary {
            self.currentUser.lastName = userDict["last_name"] as? String
            self.currentUser.firstName = userDict["first_name"] as? String
            if let emailDict = userDict["email"] as? NSDictionary {
                self.currentUser.email = emailDict["address"] as? String
            }
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MapAndListTabController") as! MapListViewController

            /* 
                Use a background queue to query the Parse API.  It queries both the total count of all Student
                Locations, the first 100 Student Locations.  At the same time on the main queue, load the
                Map & List tab controller.  Here is how I learned to use background queues:
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

