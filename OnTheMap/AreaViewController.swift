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

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let uniqueSet = StudentManager.sharedInstance.getUniqueIDs()
        uniqueStudentIDArray = Array(uniqueSet)
    }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let uniqueSetCount = uniqueStudentIDArray?.count ?? 0
        return uniqueSetCount
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UniqueStudentCell") as? UITableViewCell
        if let uniqueArray = uniqueStudentIDArray {
            let studentID = uniqueArray[indexPath.row]
            let studentName = StudentManager.sharedInstance.getStudentNameForUniqueID(studentID)
            cell!.textLabel?.text = studentName
            if let detailTextLabel = cell!.detailTextLabel {
                let numLocs = StudentManager.sharedInstance.countLocationsForUniqueID(studentID)
                detailTextLabel.text = numLocs == 1 ? "1 location" : "\(numLocs) locations"
             }
        } else {
            cell!.textLabel?.text = "Error: Students not loaded"
        }

        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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
