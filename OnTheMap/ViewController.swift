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



    override func viewDidLoad() {
        super.viewDidLoad()

        loginTextField.text = ""
    }

   @IBAction func doLogin() {
        if let userName = loginTextField.text, let password = passwordTextField.text {
            let request = NSMutableURLRequest(URL: NSURL(string: "https://www.udacity.com/api/session")!)
            request.HTTPMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = "{\"udacity\": {\"username\": \"\(userName)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)

            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request) { data, response, error in
                if error != nil {
                    println("Failed to get Udacity session: \(error)")
                    return
                }
                let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* subset response data! */
                println(NSString(data: newData, encoding: NSUTF8StringEncoding))
            }
            task.resume()
        }
    }

}

