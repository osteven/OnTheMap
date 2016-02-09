//
//  NetClient.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation

public typealias TaskRequestClosure = (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void




class NetClient {

    static let sharedInstance = NetClient()


    // MARK: -
    // MARK: constant properties
    private let UDACITY_API_SESSION_URL = "https://www.udacity.com/api/session"
    private let UDACITY_API_USERS_URL = "https://www.udacity.com/api/users/"
    private let PARSE_API_STUDENT_LOCATIONS_URL = "https://api.parse.com/1/classes/StudentLocation"
    private let PARSE_API_APP_ID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    private let PARSE_API_REST_KEY = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"

    static let PARSE_API_BATCH_SIZE = 100        // this is parameterized so it can be changed for debugging

    private let session = NSURLSession.sharedSession()


    private init() {}

    // MARK: -
    // MARK: helper class function from The Movie Manager
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {

            /* Make sure that it is a string value */
            let stringValue = "\(value)"

            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }

        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }


    // MARK: -
    // MARK: Udacity API calls
    func loadSessionIDAndUserKey(userName: String, password: String, completionHandler: TaskRequestClosure) {
        let request = NSMutableURLRequest(URL: NSURL(string: UDACITY_API_SESSION_URL)!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"udacity\": {\"username\": \"\(userName)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        // normally timeout is 60 seconds
        request.timeoutInterval = 30
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }

    func loadPublicUserData(userKey: String, completionHandler: TaskRequestClosure) {
        let request = NSMutableURLRequest(URL: NSURL(string: UDACITY_API_USERS_URL + "\(userKey)")!)
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }


    // MARK: -
    // MARK: Parse API Calls
    func loadStudentLocations(completionHandler: TaskRequestClosure) {

        var parameters = [String: AnyObject]()
        parameters["count"] = "1"
        parameters["order"] = "-createdAt"          // sort by create timestamp descending
        if NetClient.PARSE_API_BATCH_SIZE != 100 { parameters["limit"] = NetClient.PARSE_API_BATCH_SIZE }
        if StudentManager.sharedInstance.canRetrieveMoreStudentLocations() {
            parameters["skip"] = StudentManager.sharedInstance.countOfReturnedStudentLocations
        }

        let urlString = PARSE_API_STUDENT_LOCATIONS_URL + NetClient.escapedParameters(parameters)

        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        request.addValue(PARSE_API_APP_ID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(PARSE_API_REST_KEY, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }



    func postStudentLocation(student: CurrentUser, completionHandler: TaskRequestClosure) {

        let request = NSMutableURLRequest(URL: NSURL(string: PARSE_API_STUDENT_LOCATIONS_URL)!)
        request.HTTPMethod = "POST"
        request.addValue(PARSE_API_APP_ID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(PARSE_API_REST_KEY, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")


        let httpBody = student.encodedForHTTPBody
        request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)

        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }




}