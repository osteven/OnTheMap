//
//  ListViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/19/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: -
    // MARK: properties

    private let pinImage = UIImage(named: "Pin.pdf")
    @IBOutlet weak var tableView: UITableView!


    // MARK: -
    // MARK: loading and unloading
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        /*
        If the student information becomes refreshed, this view's table doesn't know about it.  So
        we should listen for the notification.
        */
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "studentsLoadedNotification:",
            name: NOTIFICATION_STUDENTS_LOADED, object: nil)
    }

    deinit {
        // http://natashatherobot.com/ios8-where-to-remove-observer-for-nsnotification-in-swift/su
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    



    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItems = UICommon.setupNavBar(self)
    }


    /*
        The first time through, the table won't be loaded yet.  But it doesn't matter
        because it will be loaded by the time the user switches to that tab.  
        This is needed for a reload after a refresh.
    */
    func studentsLoadedNotification(notification: NSNotification) {
        // don't reference self.tableView if it hasn't been created yet
       if let table = self.tableView {
            dispatch_async(dispatch_get_main_queue(), {
                table.reloadData()
                table.setContentOffset(CGPointZero, animated: true)
            })
        }
    }


    // MARK: -
    // MARK: handle header buttons



     func doPin() {
        InformationPostViewController.presentWithParent(self)
    }


    func doRefresh() {
        tableView.setContentOffset(CGPointZero, animated: true)
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
        let tabsController = self.tabBarController as! MapListViewController
        tabsController.doRefresh()
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
            if let detailTextLabel = cell!.detailTextLabel {
                detailTextLabel.text = student.mapString
            }
        } else {
            // this should never happen because the numberOfStudents() will return zero
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
