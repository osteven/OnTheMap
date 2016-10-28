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


let NOTIFICATION_MAP_SCROLL = "com.o2l.mapscroll"


class MapViewController: UIViewController, MKMapViewDelegate {


    @IBOutlet weak var mapView: MKMapView!


    // MARK: -
    // MARK: loading and unloading
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        /*
        Retrieving the student information happens in a background thread at the same time this 
        view is being loaded.  This view usually loads first, so we want to be notified when 
        the background thread finishes.
        */
        NotificationCenter.default.addObserver(self,
            selector: #selector(MapViewController.studentsLoadedNotification(_:)),
            name: NSNotification.Name(rawValue: NOTIFICATION_STUDENTS_LOADED), object: nil)


        /*
        After the user posts a new location, scroll the map to show it.
        */
        NotificationCenter.default.addObserver(self,
            selector: #selector(MapViewController.mapScrollNotification(_:)),
            name: NSNotification.Name(rawValue: NOTIFICATION_MAP_SCROLL), object: nil)
    }

    deinit {
        // http://natashatherobot.com/ios8-where-to-remove-observer-for-nsnotification-in-swift/su
        NotificationCenter.default.removeObserver(self)
    }

    func studentsLoadedNotification(_ notification: Notification) {
        self.mapView.addAnnotations(StudentManager.sharedInstance.getAnnotations())

         /*
        The map does not redraw with the added pins unless I trigger it with this dispatch to
        reset the center.  This idea came from:
        http://stackoverflow.com/questions/1694654/refresh-mkannotationview-on-a-mkmapview
        */
        DispatchQueue.main.async(execute: {
            let center = self.mapView.centerCoordinate
            self.mapView.centerCoordinate = center
        })
    }

    func mapScrollNotification(_ notification: Notification) {
        if let annotation = notification.object as? MKPointAnnotation {
            DispatchQueue.main.async(execute: {
                let span = MKCoordinateSpanMake(0.2, 0.2)
                let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            })
        }
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
            let firstTabBarItem = array[0], secondTabBarItem = array[1], thirdTabBarItem = array[2]
            firstTabBarItem.image = UIImage(named: "Map.pdf")
            secondTabBarItem.image = UIImage(named: "List.pdf")
            thirdTabBarItem.image = UIImage(named: "Target.png")

        }
    }



    // MARK: -
    // MARK: handle header buttons

    func doPin() {
        InformationPostViewController.presentWithParent(self)
    }


    func doRefresh() {
        mapView.removeAnnotations(mapView.annotations)
        let tabsController = self.tabBarController as! MapListViewController
        tabsController.doRefresh()
    }
    

    // MARK: -
    // MARK: MKMapViewDelegate support

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }

    
    func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control != annotationView.rightCalloutAccessoryView { return }
        let app = UIApplication.shared
        guard let sub = annotationView.annotation?.subtitle, let urlString = sub else { print("could not load url from annotation"); return }
        guard let url = URL(string: urlString) else { print("could not create url from annotation"); return }
        DispatchQueue.main.async { app.openURL(url) }
    }




}
