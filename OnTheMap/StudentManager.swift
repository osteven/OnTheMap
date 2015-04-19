//
//  StudentManager.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation
import MapKit

let NOTIFICATION_STUDENTS_LOADED = "com.o2l.studentmanagerloaded"

class StudentManager: Printable {

    static let sharedInstance = StudentManager()

    private var studentInfoArray: [StudentInformation]? = nil
    private var annotationsArray: [MKPointAnnotation]? = nil


    var description: String {
        var s = ""
        if studentInfoArray == nil { return "" }
        for si in studentInfoArray! { s += "\(si)\n" }
        return s
    }

    private init() {}

    func load(dictionary: [[String: AnyObject]]) {
        self.studentInfoArray = StudentInformation.studentsFromResults(dictionary)
        NSNotificationCenter.defaultCenter().postNotificationName(NOTIFICATION_STUDENTS_LOADED, object: nil)
    }

    func isLoaded() -> Bool { return self.studentInfoArray != nil }

    func numberOfStudents() -> Int {
        if studentInfoArray == nil { return 0 }
        return studentInfoArray!.count
    }

    func studentAtIndex(row: Int) -> StudentInformation? {
        if studentInfoArray == nil { return nil }
        return studentInfoArray![row]
    }

    func getAnnotations() -> [MKPointAnnotation]? {
        if studentInfoArray == nil { return nil }
        if annotationsArray == nil {
            annotationsArray = [MKPointAnnotation]()
            for student in studentInfoArray! {
                annotationsArray!.append(student.annotation)
            }
        }
        return annotationsArray
    }

}