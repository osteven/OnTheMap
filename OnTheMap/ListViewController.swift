//
//  ListViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/19/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {


    private let pinImage = UIImage(named: "Pin.pdf")

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItems = UICommon.setupNavBar(self)
    }

    // MARK: -
    //TODO: doPin
    func doPin() {

    }


    // MARK: -
    //TODO: doRefresh

    func doRefresh() {
    }



    // MARK: -
    // MARK: Table View DataSource & Delegate support


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentManager.sharedInstance.numberOfStudents()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("StudentListCell") as? UITableViewCell
        if let student = StudentManager.sharedInstance.studentAtIndex(indexPath.row) {
            cell!.textLabel?.text = student.description
        } else {
            // this will never happen because the numberOfStudents() will return zero
            cell!.textLabel?.text = "Error: Students not loaded"
        }

        cell!.imageView?.image = pinImage
        return cell!
    }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let urlstr = StudentManager.sharedInstance.studentAtIndex(indexPath.row)?.mediaURL {
            UIApplication.sharedApplication().openURL(NSURL(string: urlstr)!)
        }
    }

}
