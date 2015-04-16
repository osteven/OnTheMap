//
//  StudentManager.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation


struct StudentManager: Printable {

    let studentInfoArray: [StudentInformation]
    var description: String {
        var s = ""
        for si in studentInfoArray { s += "\(si)\n" }
        return s
    }

    init(dictionary: [[String: AnyObject]]) {
        studentInfoArray = StudentInformation.studentsFromResults(dictionary)
    }
}