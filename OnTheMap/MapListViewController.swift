//
//  MapListViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/22/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class MapListViewController: UITabBarController {


    func doRefresh() {
        StudentManager.sharedInstance.removeAll()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
            NetClient.sharedInstance.loadStudentLocations(self.studentLocationClosure)
        })
    }

    /*
    This Closure is for a query that returns both the count of all the student locations, and 
    the most recent 100 student locations.

    First, check for Connection Failure.  Next, try to parse the data and report an error if 
    it fails. Finally, grab the count first, then the top-level user dictionary and pass it 
    to the StudentManager singleton to be parsed
    */
    func studentLocationClosure(_ data: Data?, response: URLResponse?, error: NSError?) -> Void {
        if let error = error {
            UICommon.errorAlert("Connection Failure", message: "Failed to get Parse API student location data\n\n[\(error.localizedDescription)]", inViewController: self)
            return
        }
        guard let data = data else {
            UICommon.errorAlert("Connection Failure", message: "Failed to get Parse API student location data", inViewController: self)
            return
        }
        let parsedDict: NSDictionary?
        do {
            try parsedDict = JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
        } catch let parseError as NSError {
            UICommon.errorAlert("Parse Failure", message: "Could not parse location data from Parse\n\n[\(parseError.localizedDescription)]", inViewController: self)
            return
        }
        guard let topDict = parsedDict else {
            UICommon.errorAlert("Parse Failure", message: "Could not load location data from Parse", inViewController: self)
            return
        }

        /*
            Parse returns a results structure that looks like this:
                topDict=Optional({ count = 127; results = ( ... ) })
        */
        if let count = topDict["count"] as? Int {
            StudentManager.sharedInstance.countOfAllStudentLocations = count

            if let userDict = topDict["results"] as? [[String: AnyObject]] {
                if userDict.count > 0 {
                    StudentManager.sharedInstance.load(userDict, requestedBatchSize: NetClient.PARSE_API_BATCH_SIZE)

                    if StudentManager.sharedInstance.canRetrieveMoreStudentLocations() {
                        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
                            NetClient.sharedInstance.loadStudentLocations(self.studentLocationClosure) })
                    }

                    return
                }
            }
        }
        UICommon.errorAlert("Parse Failure", message: "The Parse Server did not return a valid user dictionary",
            inViewController: self)
    }



    

}
