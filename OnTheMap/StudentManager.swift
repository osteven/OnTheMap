//
//  StudentManager.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/16/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation
import MapKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


let NOTIFICATION_STUDENTS_LOADED = "com.o2l.studentmanagerloaded"

class StudentManager: CustomStringConvertible {

    // MARK: -
    // MARK: Properties

    static let sharedInstance = StudentManager()

    fileprivate var studentInfoArray = [StudentInformation]()
    fileprivate var newAnnotationsArray = [MKPointAnnotation]()

    var countOfAllStudentLocations: Int? = nil
    var countOfReturnedStudentLocations = 0

    var description: String {
        var s = ""
        for si in studentInfoArray { s += "\(si)\n" }
        return s
    }


    // MARK: -
    // MARK: Loading

    fileprivate init() {}

    func load(_ dictionary: [[String: AnyObject]], requestedBatchSize: Int) {
        countOfReturnedStudentLocations += requestedBatchSize
        let nextBatch = StudentInformation.studentsFromResults(dictionary)
        newAnnotationsArray += studentInfoArray.map { return $0.annotation }
        self.studentInfoArray += nextBatch
        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIFICATION_STUDENTS_LOADED), object: nil)
    }

    func canRetrieveMoreStudentLocations() -> Bool {
        if countOfAllStudentLocations == nil { return true }
        return countOfReturnedStudentLocations <= countOfAllStudentLocations
    }

    func getAnnotations() -> [MKPointAnnotation] {
        let returnTheseAnnotations = newAnnotationsArray
        newAnnotationsArray.removeAll()
        return returnTheseAnnotations
    }

    func appendSavedUser(_ user: CurrentUser) -> StudentInformation {
        let si = StudentInformation(user: user)
        self.studentInfoArray.insert(si, at: 0)
        self.newAnnotationsArray.append(si.annotation)
        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIFICATION_STUDENTS_LOADED), object: nil)
        return si
    }


    // MARK: -
    // MARK: Removing

    func removeAll() {
        countOfAllStudentLocations = nil
        countOfReturnedStudentLocations = 0
        newAnnotationsArray.removeAll()
        studentInfoArray.removeAll()
    }


    // MARK: -
    // MARK: Querying

    func isLoaded() -> Bool { return self.studentInfoArray.count > 0 }

    func numberOfStudents() -> Int {
        return studentInfoArray.count
    }

    func studentAtIndex(_ row: Int) -> StudentInformation? {
        if studentInfoArray.count == 0 { return nil }
        return studentInfoArray[row]
    }
    

    func getUniqueIDs() -> Set<String> {
        let array = studentInfoArray.map { return $0.uniqueKey }
        return Set(array)
    }

    func getLocationsForUniqueID(_ uniqueID: String) -> [StudentInformation] {
        return studentInfoArray.filter { $0.uniqueKey == uniqueID }
    }

    func getStudentNameForUniqueID(_ uniqueID: String) -> String {
        let array = self.getLocationsForUniqueID(uniqueID)
        return array.count > 0 ? "\(array[0].firstName) \(array[0].lastName)" : ""
    }
    func countLocationsForUniqueID(_ uniqueID: String) -> Int {
        let array = self.getLocationsForUniqueID(uniqueID)
        return array.count
    }

    func getAnnotationsForUniqueID(_ uniqueID: String) -> [MKPointAnnotation] {
        let siArray = studentInfoArray.filter { $0.uniqueKey == uniqueID }
        return siArray.map { return $0.annotation }
    }



}
