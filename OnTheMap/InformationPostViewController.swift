//
//  InformationPostViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/24/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit
import MapKit


class InformationPostViewController: UIViewController, UITextFieldDelegate {


    @IBOutlet weak var findOnMapView: UIView!
    @IBOutlet weak var whereStudyingTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var findOnMapButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.findOnMapView.alpha = 1.0
        manageFindButton(false)
        UICommon.setGradientForView(self.view)
        UICommon.setUpSpacerForTextField(whereStudyingTextField)
        whereStudyingTextField.delegate = self
        whereStudyingTextField.becomeFirstResponder()
    }


    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {

        var newText: NSString = whereStudyingTextField.text
        newText = newText.stringByReplacingCharactersInRange(range, withString: string)
        manageFindButton(newText.length > 0)
        return true
    }

    private func manageFindButton(enable: Bool) {
        findOnMapButton.enabled = enable
        if enable {findOnMapButton.alpha = 1.0 } else { findOnMapButton.alpha = 0.2 }
    }



    private func reportGeocodeError(location: String, error: NSError) {

    }

    @IBAction func findOnTheMap() {

        if let location = whereStudyingTextField.text {
            findOnMapView.alpha = 0.2
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            CLGeocoder().geocodeAddressString(location, completionHandler:
                {(placemarks, error) in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.findOnMapView.alpha = 1.0
                    if error != nil  {
                        UICommon.errorAlert("Geocode Failure", message: "Failed to get geocode for \(location)\n\n[\(error.localizedDescription)]", inViewController: self)
                        return
                    }
                    let pmArray = placemarks as? [CLPlacemark]
                    if pmArray == nil || pmArray!.count <= 0 {
                        UICommon.errorAlert("Geocode Failure", message: "No geocode for \(location)", inViewController: self)
                        return
                    }
                    let pm = pmArray![0]
                    println("name=\(pm.name)")
                    println("addr=\(pm.addressDictionary)")
                    println("post=\(pm.postalCode)")
                    println("reg=\(pm.region)")
                    println("lat=\(pm.location.coordinate.latitude)")
                    println("long=\(pm.location.coordinate.longitude)")

                    let user = (UIApplication.sharedApplication().delegate as! AppDelegate).currentUser
                    user.mapString = location
                    user.latitude = pm.location.coordinate.latitude
                    user.longitude = pm.location.coordinate.longitude
                    self.mapView.hidden = false

                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: user.latitude!, longitude: user.longitude!)
                    let fname = user.firstName ?? "?"
                    let lname = user.lastName ?? "?"
                    annotation.title = "\(fname) \(lname)"
                    self.mapView.addAnnotation(annotation)
                    let span = MKCoordinateSpanMake(0.1, 0.1)
                    let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                    self.mapView.setRegion(region, animated: true)
            })

        }
    }


}


/*
[geocoder geocodeAddressString:@"1 Infinite Loop"
completionHandler:^(NSArray* placemarks, NSError* error){
for (CLPlacemark* aPlacemark in placemarks)
{
// Process the placemark.
}
}];
*/