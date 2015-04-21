//
//  NetClient.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation

public typealias TaskRequestClosure = (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void


class NetClient {

    private let UDACITY_API_SESSION_URL = "https://www.udacity.com/api/session"
    private let UDACITY_API_USERS_URL = "https://www.udacity.com/api/users/"
    private let PARSE_API_STUDENT_LOCATIONS_URL = "https://api.parse.com/1/classes/StudentLocation"
    private let PARSE_API_APP_ID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    private let PARSE_API_REST_KEY = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"

    private let session = NSURLSession.sharedSession()


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
    // TODO: limit to 100 and page
    func loadStudentLocations(completionHandler: TaskRequestClosure) {
        let request = NSMutableURLRequest(URL: NSURL(string: PARSE_API_STUDENT_LOCATIONS_URL)!)
        request.addValue(PARSE_API_APP_ID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(PARSE_API_REST_KEY, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }

}