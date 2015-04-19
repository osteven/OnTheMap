//
//  ListViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/19/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, UITableViewDataSource {

    //    private let studentManager = (UIApplication.sharedApplication().delegate as! AppDelegate).studentManager


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
    // MARK: UITableViewDataSource support


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

//        cell!.textLabel?.text = meme.topString
//        if let i = meme.memedImage {
//            cell!.imageView?.image = i
//        }
//
//        if let detailTextLabel = cell!.detailTextLabel {
//            detailTextLabel.text = meme.bottomString
//        }
        return cell!
    }

}
