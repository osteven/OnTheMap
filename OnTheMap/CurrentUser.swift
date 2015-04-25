//
//  CurrentUser.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation
import MapKit

class CurrentUser {
    var sessionID: String? = nil

    var userKey: String? = nil      // map to uniqueKey in Parse
    var objectID: String? = nil     // generated by Parse

    var firstName: String? = nil
    var lastName: String? = nil
    var email: String? = nil        // not used

    var mediaURL: String? = nil
    var mapString: String? = nil

    var latitude: CLLocationDegrees? = nil
    var longitude: CLLocationDegrees? = nil

}