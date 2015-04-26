//
//  InformationPostViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/24/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit
import MapKit


class InformationPostViewController: UIViewController, UITextFieldDelegate, UIWebViewDelegate {


    // MARK: -
    // MARK: Properties
    @IBOutlet weak var findOnMapView: UIView!
    @IBOutlet weak var whereStudyingTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var findOnMapButton: UIButton!
    @IBOutlet weak var associatedLinkView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var linkBrowseButton: UIButton!

    private var currentURLStringIsValid = false
    private var failedWebViewLoadWithError = false

    // MARK: -
    // MARK: Loading

    static func presentWithParent(parent: UIViewController) {
        let controller = parent.storyboard?.instantiateViewControllerWithIdentifier("InformationPostingVC") as! InformationPostViewController
        parent.presentViewController(controller, animated: true, completion: nil)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        self.findOnMapView.alpha = 1.0
        self.findOnMapView.backgroundColor = UIColor.clearColor()
        self.mapView.hidden = true
        self.webView.hidden = true
        self.webView.delegate = self
        self.associatedLinkView.backgroundColor = UIColor.clearColor()
        self.swapLinkAndFindView(true)
        manageFindButton(false)
        UICommon.setGradientForView(self.view)
        UICommon.setUpSpacerForTextField(whereStudyingTextField)
        UICommon.setUpSpacerForTextField(linkTextField)
        linkTextField.delegate = self
        whereStudyingTextField.delegate = self
        whereStudyingTextField.becomeFirstResponder()

    }


    // MARK: -
    // MARK: UI

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {
            if textField == linkTextField {
                // if the entered link is not validated, disable the submit button
                manageUIForURLString(false)
                return true
            }

            // if the location find string is empty, disable the find location button
            var newText: NSString = whereStudyingTextField.text
            newText = newText.stringByReplacingCharactersInRange(range, withString: string)
            manageFindButton(newText.length > 0)
            return true
    }

    @IBAction func checkAction() {
        triggerWebViewForURLCheck(linkTextField.text)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == linkTextField {
            triggerWebViewForURLCheck(linkTextField.text)
        } else if textField == whereStudyingTextField  {
            if findOnMapButton.enabled { findOnTheMap() }
        }
        return true
    }

    private func manageFindButton(enable: Bool) {
        findOnMapButton.enabled = enable
        if enable {findOnMapButton.alpha = 1.0 } else { findOnMapButton.alpha = 0.2 }
    }

    private func swapLinkAndFindView(enableFind: Bool) {
        if enableFind {
            self.findOnMapView.hidden = false
            self.associatedLinkView.hidden = true
        } else {
            self.findOnMapView.hidden = true
            self.associatedLinkView.hidden = false
            if linkTextField.text == "" { linkTextField.text = "http://" }
            linkTextField.becomeFirstResponder()
            manageUIForURLString(false)
        }
    }



    private func showHideBrowserButton(shouldShow: Bool) {
        if shouldShow {
            linkBrowseButton.setTitle("Show Browser", forState: .Normal)
            self.mapView.hidden = false
            self.webView.hidden = true
        } else {
            linkBrowseButton.setTitle("Hide Browser", forState: .Normal)
            self.mapView.hidden = true
            self.webView.hidden = false
        }
    }

    @IBAction func linkBrowseAction() {
        showHideBrowserButton((linkBrowseButton.currentTitle == "Hide Browser"))
        if !currentURLStringIsValid { triggerWebViewForURLCheck(linkTextField.text) }
    }


    private func manageUIForActiveWebView(isActive: Bool) {
        if isActive {
            self.webView.alpha = 0.2
            associatedLinkView.alpha = 0.2
            linkTextField.resignFirstResponder()
            linkTextField.enabled = false
        } else {
            self.webView.alpha = 1.0
            linkTextField.enabled = true
            linkTextField.becomeFirstResponder()
            associatedLinkView.alpha = 1.0
        }

    }

    private func manageUIForURLString(isValid: Bool) {
        currentURLStringIsValid = isValid
        saveButton.enabled = isValid
        saveButton.alpha = isValid ? 1.0 : 0.2
    }


    // MARK: -
    // MARK: Web View Management and Link-Checking

    private func triggerWebViewForURLCheck(rawURLString: String) {

        if let components = NSURLComponents(string: rawURLString) {
            // in case they didn't enter the 'http://'
            if components.scheme == nil { components.scheme = "http" }
            if let url = components.URL {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let requestObj = NSMutableURLRequest(URL: url)
                requestObj.timeoutInterval = 30
                self.webView.loadRequest(requestObj)
                manageUIForActiveWebView(true)
            }
        }
    }


    // http://stackoverflow.com/questions/2491410/get-current-url-of-uiwebview/3654403#3654403
    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        // don't restore the UI if the error alert dialog is showing
        if (!failedWebViewLoadWithError) { manageUIForActiveWebView(false) }
        if let currentURL = self.webView.request?.URL?.absoluteString {
            if currentURL != "about:blank" {
                linkTextField.text = currentURL
                manageUIForURLString(true)
            } else {
                manageUIForURLString(false)
            }
        } else {
            manageUIForURLString(false)
        }
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {

        // I think these errors are unnecessarily triggered if the host forwards the request
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled { return }
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCannotConnectToHost { return }

        // Flag to prevent restoration of the UI before the user dismisses the alert
        failedWebViewLoadWithError = true


        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        /*
        If you load a valid URL, then type in another invalid URL, the web view
        does not redraw to erase the previous valid page.  So, force it to "about:blank"
        */
        clearWebView()

        var errorStr = ""
        if error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorNetworkConnectionLost {
            errorStr = "Not connected to the internet\n\n\(error.localizedDescription)"
        } else {
            errorStr = "\(error.localizedDescription)\n\n[\(error.code)]"
        }

        // don't restore the UI until the user dismisses the alert
        UICommon.errorAlertWithHandler("URL Validation Failure", message: errorStr, inViewController: self, handler: alertHandler)
    }

    private func alertHandler(action: UIAlertAction!) -> Void {
        self.manageUIForActiveWebView(false)
        self.manageUIForURLString(false)
        self.failedWebViewLoadWithError = false      // flag that the error has been handled
    }

    private func clearWebView() {
        if let url = NSURL(string: "about:blank") {
            let requestObj = NSURLRequest(URL: url)
            self.webView.loadRequest(requestObj)
        }
    }

    // MARK: -
    // MARK: Geocoding

    private func reportGeocodeError(location: String, error: NSError) {
        var errorStr = ""
        if error.code == CLError.LocationUnknown.rawValue {
            errorStr = "Location unknown: '\(location)'"
        } else if error.code == CLError.Network.rawValue {
            errorStr = "Geocode network connection is not responding"
        } else if error.code == CLError.GeocodeFoundNoResult.rawValue {
            errorStr = "No geocode result found for: '\(location)'"
        } else {
            errorStr = "Unknow Core Location error"
        }
        errorStr += "\n\n[\(error.localizedDescription)]"
        UICommon.errorAlert("Geocode Failure", message: errorStr, inViewController: self)
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
                        self.reportGeocodeError(location, error: error)
                        return
                    }
                    let pmArray = placemarks as? [CLPlacemark]
                    if pmArray == nil || pmArray!.count <= 0 {
                        // I don't know if this will ever happen
                        UICommon.errorAlert("Geocode Failure", message: "No geocode for \(location)", inViewController: self)
                        return
                    }
                    let pm = pmArray![0]
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
                    self.swapLinkAndFindView(false)
            })

        }
    }




    // MARK: -
    // MARK: Save Data


    @IBAction func saveData() {
        if currentURLStringIsValid {
        } else {
            UICommon.errorAlert("Cannot Save", message: "Cannot save the location without a valid link", inViewController: self)
            return
        }
    }

}

