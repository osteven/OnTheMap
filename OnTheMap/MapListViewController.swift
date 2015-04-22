//
//  MapListViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/22/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class MapListViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

     }




    /*
    First, check for Connection Failure.  Next, try to parse the data and report error if it fails.
    Finally, grab the top-level user dictionary and pass it to the StudentManager singleton to be parsed.
    */
    func studentLocationClosure(data: NSData!, response: NSURLResponse!, error: NSError!) -> Void {
        if error != nil {
            UICommon.errorAlert("Connection Failure", message: "Failed to get Parse API student location data\n\n[\(error.localizedDescription)]", inViewController: self)
            return
        }
        var parseError: NSError? = nil
        let topDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
        if let err = parseError {
            UICommon.errorAlert("Parse Failure", message: "Could not parse location data from Parse\n\n[\(err.localizedDescription)]", inViewController: self)
            return
        }

        if let userDict = topDict!["results"] as? [[String: AnyObject]] {
            if userDict.count > 0 {
                StudentManager.sharedInstance.load(userDict)
                return
            }
        }
        UICommon.errorAlert("Parse Failure", message: "The Parse Server did not return a valid user dictionary", inViewController: self)
    }



    

}
