//
//  NetClient.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation

public typealias RequestClosure = (result: AnyObject!, error: NSError?) -> Void
public typealias TaskRequestClosure = (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void


class NetClient {

    let PARSE_API_STUDENT_LOCATIONS_URL = "https://api.parse.com/1/classes/StudentLocation"
    let PARSE_API_APP_ID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    let PARSE_API_REST_KEY = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"

    let session = NSURLSession.sharedSession()




    func loadSessionIDAndUserKey(userName: String, password: String, completionHandler: TaskRequestClosure) {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.udacity.com/api/session")!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"udacity\": {\"username\": \"\(userName)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }


    func loadStudentLocations(completionHandler: TaskRequestClosure) {
        let request = NSMutableURLRequest(URL: NSURL(string: PARSE_API_STUDENT_LOCATIONS_URL)!)
        request.addValue(PARSE_API_APP_ID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(PARSE_API_REST_KEY, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }



//    public func loadStudentLocations(completionHandler: NSURLSessionDataTask) {
//        let request = NSMutableURLRequest(URL: NSURL(string: PARSE_API_STUDENT_LOCATIONS_URL)!)
//        request.addValue(PARSE_API_APP_ID, forHTTPHeaderField: "X-Parse-Application-Id")
//        request.addValue(PARSE_API_REST_KEY, forHTTPHeaderField: "X-Parse-REST-API-Key")
//        let session = NSURLSession.sharedSession()
//        let task = session.dataTaskWithRequest(request) { data, response, error in
//            if error != nil { // Handle error...
//                println("Failed to get Parse API student location data: \(error)")
//                return
//            }
//            //    println(NSString(data: data, encoding: NSUTF8StringEncoding))
//            var parseError: NSError? = nil
//            let topDict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as? NSDictionary
//            if let error = parseError {
//                println("Failed to parse Parse data: \(error)")
//            } else {
//                if let userDict = topDict!["results"] as? [[String: AnyObject]] {
//                    self.studentManager = StudentManager(dictionary: userDict)
//                    println("\(self.studentManager)")
//                    //  dispatch_async(dispatch_get_main_queue(), {  })
//                } else {
//                    println("Failed to find user dictionary")
//                }
//            }
//        }
//        task.resume()
//    }




//
//    func taskForRequest(urlRequest: NSURLRequest, completionHandler: RequestClosure) -> NSURLSessionDataTask {
//
//        let task = session.dataTaskWithRequest(urlRequest) {data, response, downloadError in
//
//            /* 5/6. Parse the data and use the data (happens in completion handler) */
//            if let error = downloadError {
//                let newError = NetClient.errorForData(data, response: response, error: error)
//                completionHandler(result: nil, error: downloadError)
//            } else {
//                NetClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
//            }
//        }
//
//        /* 7. Start the request */
//        task.resume()
//        return task
//    }
//
    /* Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error */
//    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
//
//        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject] {
//
//            if let errorMessage = parsedResult[TMDBClient.JSONResponseKeys.StatusMessage] as? String {
//
//                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
//
//                return NSError(domain: "TMDB Error", code: 1, userInfo: userInfo)
//            }
//        }
//
//        return error
//    }
//
//
//
//
//    func taskForGETMethod(method: String, parameters: [String: AnyObject], completionHandler: RequestClosure) -> NSURLSessionDataTask {
//
//        /* 1. Set the parameters */
//        var mutableParameters = parameters
//        mutableParameters[ParameterKeys.ApiKey] = Constants.ApiKey
//
//        /* 2/3. Build the URL and configure the request */
//        let urlString = Constants.BaseURLSecure + method + TMDBClient.escapedParameters(mutableParameters)
//        let url = NSURL(string: urlString)!
//        let request = NSURLRequest(URL: url)
//
//        /* 4. Make the request */
//        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
//
//            /* 5/6. Parse the data and use the data (happens in completion handler) */
//            if let error = downloadError {
//                let newError = TMDBClient.errorForData(data, response: response, error: error)
//                completionHandler(result: nil, error: downloadError)
//            } else {
//                TMDBClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
//            }
//        }
//
//        /* 7. Start the request */
//        task.resume()
//
//        return task
//    }


}