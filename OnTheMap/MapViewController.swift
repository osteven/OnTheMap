//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/17/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {


    @IBOutlet weak var mapView: MKMapView!


    // MARK: -
    // MARK: loading and unloading
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        /*
        Retrieving the student information happens in a background thread at the same time this view is 
        being loaded.  This view usually loads first, so we want to be notified when the background 
        thread finishes.
        */
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "studentsLoadedNotification:",
            name: NOTIFICATION_STUDENTS_LOADED, object: nil)
    }

    deinit {
        // http://natashatherobot.com/ios8-where-to-remove-observer-for-nsnotification-in-swift/su
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func studentsLoadedNotification(notification: NSNotification) {
        self.mapView.addAnnotations(StudentManager.sharedInstance.getAnnotations())

//        let num = StudentManager.sharedInstance.numberOfStudents()
//        println("num=\(num)")

         /*
        The map does not redraw with the added pins unless I trigger it with this dispatch to
        reset the center.  This idea came from:
        http://stackoverflow.com/questions/1694654/refresh-mkannotationview-on-a-mkmapview
        */
        dispatch_async(dispatch_get_main_queue(), {
            let center = self.mapView.centerCoordinate
            self.mapView.centerCoordinate = center
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItems = UICommon.setupNavBar(self)
        if StudentManager.sharedInstance.isLoaded() {
            self.mapView.addAnnotations(StudentManager.sharedInstance.getAnnotations())
        }

        /*
            The tab bar item for the list tab is not showing up.  It delays several minutes before 
            drawing as described at this link:
            http://stackoverflow.com/questions/25995112/tabbaritem-icon-does-not-appear-immediately-in-ios-8
            I can force it to draw by redundantly setting the image in code.
        */
        if let array = self.tabBarController?.tabBar.items {
            if let firstTabBarItem = array[0] as? UITabBarItem, secondTabBarItem = array[1] as? UITabBarItem {
                firstTabBarItem.image = UIImage(named: "Map.pdf")
                secondTabBarItem.image = UIImage(named: "List.pdf")
            }
        }
    }



    // MARK: -
    //TODO: doPin
    func doPin() {

    }


    func doRefresh() {
        mapView.removeAnnotations(mapView.annotations)
        let tabsController = self.tabBarController as! MapListViewController
        tabsController.doRefresh()
    }
    

    // MARK: -
    // MARK: MKMapViewDelegate support

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {

        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .Red
            pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
        } else {
            pinView!.annotation = annotation
        }

        return pinView
    }

    func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()

            /*
            Wrap the openURL call in a delayed dispatch in order to avoid the error:
            <Snapshotting a view that has not been rendered results in an empty snapshot.
            Ensure your view has been rendered at least once before snapshotting or snapshot 
            after screen updates.>
            It seems to be a similar problem to this:
            http://stackoverflow.com/questions/25884801/ios-8-snapshotting-a-view-that-has-not-been-rendered-results-in-an-empty-snapsho
            
            Update: This solution does not work after all.
            */
            let delayInSeconds = Int64(0.4 * Double(NSEC_PER_SEC));
            dispatch_time(DISPATCH_TIME_NOW, delayInSeconds);
            dispatch_async(dispatch_get_main_queue(), {
                app.openURL(NSURL(string: annotationView.annotation.subtitle!)!)
            })
        }
    }




}
