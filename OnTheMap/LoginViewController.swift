//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/15/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate, CAAnimationDelegate {

    // MARK: -
    // MARK: properties
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginContainerView: UIView!

    fileprivate let currentUser = (UIApplication.shared.delegate as! AppDelegate).currentUser
    fileprivate var errorMessage = ""


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
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            manageUI(false)
            NetClient.sharedInstance.loadSessionIDAndUserKey(userName, password: password, completionHandler: sessionAndUserKeyClosure)
        }
    }

    @IBAction func udacitySignUp() {
        UIApplication.shared.openURL(URL(string: "https://www.udacity.com/account/auth#!/signup")!)
    }

    /*
        First, restore the UI.  Next, check for Connection Failure.  Third, try to parse the 
        data and report error if it fails.  Fourth, grab the user key and session ID from 
        the parsed data or report a bad login.  Finally, ask the NetClient to request the 
        user data from the Udacity API, passing in the next closure.
    */
    func sessionAndUserKeyClosure(_ data: Data?, response: URLResponse?, error: Error?) -> Void {
        var stillNeedLogin = true
        defer { DispatchQueue.main.async(execute: { self.manageUI(stillNeedLogin) })  }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if let error = error {
            UICommon.errorAlert("Connection Failure", message: "Failed to connect to Udacity\n\n[\(error.localizedDescription)]", inViewController: self)
            return
        }
        guard let data = data else {
            UICommon.errorAlert("Connection Failure", message: "Failed to connect to Udacity", inViewController: self)
            return
        }
        let range = Range(5...data.count)
        let newData = data.subdata(in: range)

        //let newData = data.subdata(in: NSMakeRange(5, data.count - 5))  /* subset response data! */
        let parsedDict: NSDictionary?
        do {
            try parsedDict = JSONSerialization.jsonObject(with: newData, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
        } catch let parseError as NSError {
            UICommon.errorAlert("Parse Failure", message: "Could not parse account data from Udacity\n\n[\(parseError.localizedDescription)]", inViewController: self)
            return
        }
        guard let topDict = parsedDict else {
            UICommon.errorAlert("Parse Failure", message: "Could not parse account data from Udacity", inViewController: self)
            return
        }


        if let accountDict = topDict["account"] as? NSDictionary, let sessionDict = topDict["session"] as? NSDictionary {
            if let userKey = accountDict["key"] as? String {
                stillNeedLogin = false
                self.currentUser.userKey = userKey
                if let sess = sessionDict["id"] as? String { self.currentUser.sessionID = sess }
                NetClient.sharedInstance.loadPublicUserData(userKey, completionHandler: publicUserDataClosure)
            } else {
                UICommon.errorAlert("Udacity Login Failure", message: "The Udacity API failed to return a User Key", inViewController: self)
            }
        } else if let status = topDict["status"] as? Int, let errorStr = topDict["error"] as? NSString {
            // else, found an error message in the response
            self.errorMessage = "The email or password you \nentered is invalid\n\n[\(status):\(errorStr)]"
            DispatchQueue.main.async(execute: { self.reportLoginFailureWithShake() })
        }
    }

    //http://stackoverflow.com/questions/3844557/uiview-shake-animation
    fileprivate func reportLoginFailureWithShake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.delegate = self
        animation.duration = 0.10
        animation.repeatCount = 6
        animation.autoreverses = true

        let fromPoint = CGPoint(x: loginContainerView.center.x - 20.0, y: loginContainerView.center.y)
        animation.fromValue = NSValue(cgPoint: fromPoint)

        let toPoint = CGPoint(x: loginContainerView.center.x + 20.0, y: loginContainerView.center.y)
        animation.toValue = NSValue(cgPoint: toPoint)

        loginContainerView.layer.add(animation, forKey: "position")
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        UICommon.errorAlert("Login Failure", message: self.errorMessage, inViewController: self)
    }

    /*
        First, check for Connection Failure.  Next, try to parse the data and report error 
        if it fails. Third, grab the user name and email from the parsed data.  Next, 
        initiate a NetClient background queue request for the location list, passing in 
        the next closure.  Finally load the Map/List controller in the main queue.
    */
    func publicUserDataClosure(_ data: Data?, response: URLResponse?, error: Error?) -> Void {
        if let error = error {
            UICommon.errorAlert("Connection Failure", message: "Failed to get Udacity public user data\n\n[\(error.localizedDescription)]",
                inViewController: self)
            return
        }
        guard let data = data else {
            UICommon.errorAlert("Connection Failure", message: "Failed to get Udacity public user data", inViewController: self)
            return
        }
        let range = Range(5...data.count)
        let newData = data.subdata(in: range)

        //let newData = data.subdata(in: NSMakeRange(5, data.count - 5)) /* subset response data! */



        let parsedDict: NSDictionary?
        do {
            try parsedDict = JSONSerialization.jsonObject(with: newData, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
        } catch let parseError as NSError {
            UICommon.errorAlert("Parse Failure", message: "Could not parse user data from Udacity\n\n[\(parseError.localizedDescription)]",
                inViewController: self)
            return
        }
        guard let topDict = parsedDict else {
            UICommon.errorAlert("Parse Failure", message: "Could not parse user data from Udacity", inViewController: self)
            return
        }

        guard let userDict = topDict["user"] as? [String: AnyObject] else {
            UICommon.errorAlert("Parse Failure", message: "Could not get user data from Udacity", inViewController: self)
            return
        }

        self.currentUser.loadPublicData(userDict)
        guard let controller = self.storyboard?.instantiateViewController(withIdentifier: "MapAndListTabController")
            as? MapListViewController else { fatalError("Could not find MapAndListTabController") }

        /*
        Use a background queue to query the Parse API.  It queries both the total count of all Student Locations, 
        the first 100 Student Locations.  At the same time on the main queue, load the Map & List tab controller.  
        Here is how I learned to use background queues:
        http://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift
        */

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            NetClient.sharedInstance.loadStudentLocations(controller.studentLocationClosure)
        }

        DispatchQueue.main.async {
            self.present(controller, animated: true, completion: nil)
        }

    }


    // MARK: -
    // MARK: text field and login button management

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let loginText = loginTextField.text, let passwordText = passwordTextField.text else { /* Cannot happen? */ return true }
        if loginText.characters.count > 0 && passwordText.characters.count > 0 {
            textField.resignFirstResponder()
            DispatchQueue.main.async(execute: { self.doLogin() })
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
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {

        var enableLogin: Bool = false
        var newPasswordText: NSString = passwordTextField.text as NSString? ?? ""
        var newLoginText: NSString = loginTextField.text as NSString? ?? ""

        if textField == loginTextField {
            newLoginText = newLoginText.replacingCharacters(in: range, with: string) as NSString
        } else {
            newPasswordText = newPasswordText.replacingCharacters(in: range, with: string) as NSString
        }
        enableLogin = (newLoginText.length >= 4) && (newPasswordText.length >= 4)
        if enableLogin {
            enableLogin = (newLoginText.range(of: ".").location != NSNotFound) && (newLoginText.range(of: "@").location != NSNotFound)
        }
        manageLoginButton(enableLogin)
        return true
    }

    fileprivate func manageUI(_ enable: Bool) {
        if !enable {
            loginTextField.resignFirstResponder()
            passwordTextField.resignFirstResponder()
            loginTextField.alpha = 0.2
            passwordTextField.alpha = 0.2
        } else {
            loginTextField.alpha = 0.6
            passwordTextField.alpha = 0.6
        }
        loginTextField.isEnabled = enable
        passwordTextField.isEnabled = enable
        manageLoginButton(enable)
    }

    fileprivate func manageLoginButton(_ enable: Bool) {
        loginButton.isEnabled = enable
        if enable {loginButton.alpha = 1.0 } else { loginButton.alpha = 0.2 }
    }


}

