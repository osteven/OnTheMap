//
//  StudentInformation.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation
import MapKit


struct StudentInformation: Printable {

    let uniqueKey: String
    let firstName: String
    let lastName: String
    let mapString: String
    let mediaURL: String
    let longitude: CLLocationDegrees
    let latitude: CLLocationDegrees
    let annotation: MKPointAnnotation

    var description: String {
        return "\(firstName) \(lastName)"
    }

    init?(dictionary: [String: AnyObject]) {
        if let s = dictionary["uniqueKey"] as? String {
            self.uniqueKey = s
        } else {
            return nil
        }
        if let s = dictionary["firstName"] as? String {
            self.firstName = s
        } else {
            return nil
        }
        if let s = dictionary["lastName"] as? String {
            self.lastName = s
        } else {
            return nil
        }
        if let s = dictionary["mapString"] as? String {
            self.mapString = s
        } else {
            return nil
        }
        if let s = dictionary["mediaURL"] as? String {
            self.mediaURL = s
        } else {
            return nil
        }
        if let s = dictionary["longitude"] as? Double {
            // sanity check on bad data to prevent the map from crashing later
            if s < -180.0 || s > 180.0 { return nil }
            self.longitude = CLLocationDegrees(s)
        } else {
            return nil
        }
        if let s = dictionary["latitude"] as? Double {
            // sanity check on bad data to prevent the map from crashing later
            if s < -90.0 || s > 90.0 { return nil }
            self.latitude = CLLocationDegrees(s)
        } else {
            return nil
        }
        annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.title = "\(firstName) \(lastName)"
        annotation.subtitle = mediaURL
    }


    init(user: CurrentUser) {
        self.uniqueKey = user.userKey
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.mapString = user.mapString
        self.mediaURL = user.mediaURL
        self.longitude = user.longitude
        self.latitude = user.latitude
        self.annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.title = "\(self.firstName) \(self.lastName)"
        annotation.subtitle = self.mediaURL
    }

    /* Helper: Given an array of dictionaries, convert them to an array of StudentInformation objects */
    static func studentsFromResults(results: [[String: AnyObject]]) -> [StudentInformation] {
        var students = [StudentInformation]()

        for result in results {
            if let si = StudentInformation(dictionary: result) {
                students.append(si)
            } else {
                // uncomment if you want to see bad data that has been posted to the server.
                // println("Failed to create StudentInformation: \(result)")
            }
        }
        return students
    }


}

/*





[
uniqueKey: 231757155,
createdAt: 2015-04-24T17:52:57.962Z,
updatedAt: 2015-04-24T17:52:57.962Z,
objectId: DKkCLsxkvv,

latitude: 41.02653,
longitude: -73.62855, 
firstName: James
lastName: Gilchrist,
mediaURL: http://www.bevellabs.com,
mapString: Greenwich, CT, United States,
]

"mediaURL" : "http:\/\/www.linkedin.com\/in\/jessicauelmen\/en",
"firstName" : "Jessica",
"longitude" : -82.75676799999999,
"uniqueKey" : "872458750",
"latitude" : 28.1461248,
"objectId" : "kj18GEaWD8",
"createdAt" : "2015-02-24T22:27:14.456Z",
"updatedAt" : "2015-04-01T17:46:23.078Z",
"mapString" : "Tarpon Springs, FL",
"lastName" : "Uelmen"
*/