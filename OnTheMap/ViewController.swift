//
//  ViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/15/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var testBtn: UIButton!



    private let netClient = NetClient()
    private var studentManager: StudentManager? = nil

    private let currentUser = (UIApplication.sharedApplication().delegate as! AppDelegate).currentUser


    override func viewDidLoad() {
        super.viewDidLoad()

        // spacing from here: http://stackoverflow.com/questions/7565645/indent-the-text-in-a-uitextfield
        let loginSpacer = UIView(frame: CGRectMake(0, 0, 10, 10))
        loginTextField.leftViewMode = .Always
        loginTextField.leftView = loginSpacer
        let passSpacer = UIView(frame: CGRectMake(0, 0, 10, 10))
        passwordTextField.leftViewMode = .Always
        passwordTextField.leftView = passSpacer

        self.configureUI()

        testBtn.addTarget(self, action: "test", forControlEvents: .TouchUpInside)



    }


    // MARK: -
    // MARK: login-related functions

    @IBAction func doLogin() {
        if let userName = loginTextField.text, let password = passwordTextField.text {
            self.loadSessionIDAndUserKey(userName, password: password)
        }
    }

    @IBAction func test() {
println("test")
    }

    private func loadSessionIDAndUserKey(userName: String, password: String) {
        netClient.loadSessionIDAndUserKey(userName, password: password, completionHandler: sessionAndUserKeyClosure)
    }

    private func loadPublicUserData() {
        if self.currentUser.userKey == nil { println("loadPublicUserData but userKey is nil"); return }
        netClient.loadPublicUserData(self.currentUser.userKey!, completionHandler: publicUserDataClosure)
    }

    private func loadStudentLocations() {
        netClient.loadStudentLocations(studentLocationClosure)
    }

    // MARK: -
    //TODO: slide up and dismiss the keyboard


    // MARK: -
    // MARK: login-related closures

    func sessionAndUserKeyClosure(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void {
        if error != nil {
            println("Failed to get Udacity session: \(error)")
            return
        }
        let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))  /* subset response data! */
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let error = parseError {
            println("Failed to parse Udacity data: \(error)")
        } else {
            if let accountDict = topDict!["account"] as? NSDictionary, let sessionDict = topDict!["session"] as? NSDictionary {
                self.currentUser.userKey = accountDict["key"] as? String
                self.currentUser.sessionID = sessionDict["id"] as? String
                println("\(self.currentUser.userKey)\n\(self.currentUser.sessionID)")
                dispatch_async(dispatch_get_main_queue(), { self.loadPublicUserData() })
            }
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
                //   println("\(self.firstName)\n\(self.lastName)\n\(self.email)")
                //            dispatch_async(dispatch_get_main_queue(), { self.loadStudentLocations() })

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
        //    println(NSString(data: data, encoding: NSUTF8StringEncoding))
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let error = parseError {
            println("Failed to parse Parse data: \(error)")
        } else {
            if let userDict = topDict!["results"] as? [[String: AnyObject]] {
                self.studentManager = StudentManager(dictionary: userDict)
                println("\(self.studentManager)")
                //  dispatch_async(dispatch_get_main_queue(), {  })
            } else {
                println("Failed to find user dictionary")
            }
        }
    }

    // 251, 155, 43  -> 252, 112, 33
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
    }

}

