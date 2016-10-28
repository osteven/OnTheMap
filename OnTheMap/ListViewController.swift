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

    fileprivate let pinImage = UIImage(named: "Pin.pdf")
    @IBOutlet weak var tableView: UITableView!


    // MARK: -
    // MARK: loading and unloading
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        /*
        If the student information becomes refreshed, this view's table doesn't know about it.  So
        we should listen for the notification.
        */
        NotificationCenter.default.addObserver(self,
            selector: #selector(ListViewController.studentsLoadedNotification(_:)),
            name: NSNotification.Name(rawValue: NOTIFICATION_STUDENTS_LOADED), object: nil)
    }

    deinit {
        // http://natashatherobot.com/ios8-where-to-remove-observer-for-nsnotification-in-swift/su
        NotificationCenter.default.removeObserver(self)
    }
    



    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItems = setupNavBar()
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
                table.setContentOffset(CGPoint.zero, animated: true)
            })
        }
    }


    // MARK: -
    // MARK: handle header buttons

    private func setupNavBar() -> [UIBarButtonItem] {
        let pinButton = UIBarButtonItem(image: UIImage(named: "Pin.pdf"), style: .plain, target: self, action: #selector(ListViewController.doPin))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(ListViewController.doRefresh))
        return [refreshButton, pinButton]
    }



    func doPin() {
        InformationPostViewController.presentWithParent(self)
    }


    func doRefresh() {
        tableView.setContentOffset(CGPoint.zero, animated: true)
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
        let tabsController = self.tabBarController as! MapListViewController
        tabsController.doRefresh()
    }


    // MARK: -
    // MARK: Table View DataSource & Delegate support


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentManager.sharedInstance.numberOfStudents()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StudentListCell") else { fatalError("Could not load StudentListCell") }
        if let student = StudentManager.sharedInstance.studentAtIndex(indexPath.row) {
            cell.textLabel?.text = student.description
            if let detailTextLabel = cell.detailTextLabel {
                detailTextLabel.text = student.mapString
            }
        } else {
            // this should never happen because the numberOfStudents() will return zero
            cell.textLabel?.text = "Error: Students not loaded"
        }

        cell.imageView?.image = pinImage
        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let urlstr = StudentManager.sharedInstance.studentAtIndex(indexPath.row)?.mediaURL {
            UIApplication.shared.openURL(URL(string: urlstr)!)
        }
    }

}
