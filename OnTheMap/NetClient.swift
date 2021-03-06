
//
//  NetClient.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation

public typealias TaskRequestClosure = (Data?, URLResponse?, Error?) -> Void



// https://api.parse.com/1/classes becomes https://parse.udacity.com/parse/classes



class NetClient {

    static let sharedInstance = NetClient()


    // MARK: -
    // MARK: constant properties
    fileprivate let UDACITY_API_SESSION_URL = "https://www.udacity.com/api/session"
    fileprivate let UDACITY_API_USERS_URL = "https://www.udacity.com/api/users/"
    fileprivate let PARSE_API_STUDENT_LOCATIONS_URL = "https://parse.udacity.com/parse/classes/StudentLocation"
    fileprivate let PARSE_API_APP_ID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    fileprivate let PARSE_API_REST_KEY = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"

    static let PARSE_API_BATCH_SIZE = 100        // this is parameterized so it can be changed for debugging

    fileprivate let session = URLSession.shared


    fileprivate init() {}

    // MARK: -
    // MARK: helper class function from The Movie Manager
    class func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {

            /* Make sure that it is a string value */
            let stringValue = "\(value)"

            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)

            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }

        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }



    // MARK: -
    // MARK: Udacity API calls
    func loadSessionIDAndUserKey(_ userName: String, password: String, completionHandler: @escaping TaskRequestClosure) {
        var request = URLRequest(url: URL(string: UDACITY_API_SESSION_URL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(userName)\", \"password\": \"\(password)\"}}".data(using: String.Encoding.utf8)
        // normally timeout is 60 seconds
        request.timeoutInterval = 30
        let task = session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }

    func loadPublicUserData(_ userKey: String, completionHandler: @escaping TaskRequestClosure) {
        let request = URLRequest(url: URL(string: UDACITY_API_USERS_URL + "\(userKey)")!)
        let task = session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }


    // MARK: -
    // MARK: Parse API Calls
    func loadStudentLocations(_ completionHandler: @escaping TaskRequestClosure) {

        var parameters = [String: AnyObject]()
        parameters["count"] = "1" as AnyObject?
        parameters["order"] = "-createdAt" as AnyObject?          // sort by create timestamp descending
        if NetClient.PARSE_API_BATCH_SIZE != 100 { parameters["limit"] = NetClient.PARSE_API_BATCH_SIZE as AnyObject? }
        if StudentManager.sharedInstance.canRetrieveMoreStudentLocations() {
            parameters["skip"] = StudentManager.sharedInstance.countOfReturnedStudentLocations as AnyObject?
        }

        let urlString = PARSE_API_STUDENT_LOCATIONS_URL + NetClient.escapedParameters(parameters)

        guard let url = URL(string: urlString) else { fatalError("could not generate url: \(urlString)") }

        var request = URLRequest(url: url)
        request.addValue(PARSE_API_APP_ID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(PARSE_API_REST_KEY, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let task = session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }



    func postStudentLocation(_ student: CurrentUser, completionHandler: @escaping TaskRequestClosure) {

        var request = URLRequest(url: URL(string: PARSE_API_STUDENT_LOCATIONS_URL)!)
        request.httpMethod = "POST"
        request.addValue(PARSE_API_APP_ID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(PARSE_API_REST_KEY, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")


        let httpBody = student.encodedForHTTPBody
        request.httpBody = httpBody.data(using: String.Encoding.utf8)

        let task = session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }




}
