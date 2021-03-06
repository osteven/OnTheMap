//
//  AreaViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/28/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit
import MapKit

class AreaViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var uniqueStudentIDArray: [String]! = nil
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!




    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        /*
        If the student information becomes refreshed, this view's table doesn't know about it.  So
        we should listen for the notification.
        */
        NotificationCenter.default.addObserver(self,
            selector: #selector(AreaViewController.studentsLoadedNotification(_:)),
            name: NSNotification.Name(rawValue: NOTIFICATION_STUDENTS_LOADED), object: nil)
    }

    deinit {
        // http://natashatherobot.com/ios8-where-to-remove-observer-for-nsnotification-in-swift/su
        NotificationCenter.default.removeObserver(self)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let uniqueSet = StudentManager.sharedInstance.getUniqueIDs()
        uniqueStudentIDArray = Array(uniqueSet)
    }

    /*
    The first time through, the table won't be loaded yet.  But it doesn't matter
    because it will be loaded by the time the user switches to that tab.
    This is needed for a reload after a refresh.
    */
    func studentsLoadedNotification(_ notification: Notification) {

        // don't reference self.tableView if it hasn't been created yet
        if let table = self.tableView {
            DispatchQueue.main.async(execute: {
                table.reloadData()
                if let indexPath = table.indexPathForSelectedRow {
                    table.selectRow(at: indexPath, animated: false, scrollPosition: .top)
                }
            })
        }
    }






    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let uniqueSetCount = uniqueStudentIDArray?.count ?? 0
        return uniqueSetCount
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UniqueStudentCell") else { fatalError("could not load UniqueStudentCell") }
        if let uniqueArray = uniqueStudentIDArray {
            let studentID = uniqueArray[indexPath.row]
            let studentName = StudentManager.sharedInstance.getStudentNameForUniqueID(studentID)
            cell.textLabel?.text = studentName
            if let detailTextLabel = cell.detailTextLabel {
                let numLocs = StudentManager.sharedInstance.countLocationsForUniqueID(studentID)
                detailTextLabel.text = numLocs == 1 ? "1 location" : "\(numLocs) locations"
             }
        } else {
            cell.textLabel?.text = "Error: Students not loaded"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mapView.removeAnnotations(mapView.annotations)
        if let uniqueArray = uniqueStudentIDArray {
            let studentID = uniqueArray[indexPath.row]
            let annotationsArray = StudentManager.sharedInstance.getAnnotationsForUniqueID(studentID)
            if annotationsArray.count > 0 {
                self.mapView.addAnnotations(annotationsArray)
                let span = MKCoordinateSpanMake(0.4, 0.4)
                let region = MKCoordinateRegion(center: annotationsArray[0].coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }



}
