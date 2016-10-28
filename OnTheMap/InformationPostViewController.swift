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

    fileprivate var currentURLStringIsValid = false
    fileprivate var failedWebViewLoadWithError = false

    // MARK: -
    // MARK: Loading


    /*
    Convenience loader so that this code needs not be duplicated in the tab VCs that both load this VC
    */
    static func presentWithParent(_ parent: UIViewController) {
        let controller = parent.storyboard?.instantiateViewController(withIdentifier: "InformationPostingVC") as! InformationPostViewController
        parent.present(controller, animated: true, completion: nil)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        self.findOnMapView.alpha = 1.0
        self.findOnMapView.backgroundColor = UIColor.clear
        self.mapView.isHidden = true
        self.webView.isHidden = true
        self.webView.delegate = self
        self.associatedLinkView.backgroundColor = UIColor.clear
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

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
            if textField == linkTextField {
                // if the entered link is not validated, disable the submit button
                manageUIReadyForSubmit(false)
                return true
            }

            // if the location find string is empty, disable the find location button
            var newText: NSString = whereStudyingTextField.text as NSString? ?? ""
            newText = newText.replacingCharacters(in: range, with: string) as NSString
            manageFindButton(newText.length > 0)
            return true
    }

    @IBAction func checkAction() {
        guard let linkText = linkTextField.text else { return }
        triggerWebViewForURLCheck(linkText)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == linkTextField {
            guard let textBody = textField.text else { return /* I don't think this can happen */ false }
            triggerWebViewForURLCheck(textBody)
        } else if textField == whereStudyingTextField  {
            if findOnMapButton.isEnabled { findOnTheMap() }
        }
        return true
    }

    fileprivate func manageFindButton(_ enable: Bool) {
        findOnMapButton.isEnabled = enable
        if enable {findOnMapButton.alpha = 1.0 } else { findOnMapButton.alpha = 0.2 }
    }

    fileprivate func swapLinkAndFindView(_ enableFind: Bool) {
        if enableFind {
            self.findOnMapView.isHidden = false
            self.associatedLinkView.isHidden = true
        } else {
            self.findOnMapView.isHidden = true
            self.associatedLinkView.isHidden = false
            self.view.endEditing(true)
            manageUIReadyForSubmit(false)
        }
    }



    fileprivate func showHideBrowserButton(_ shouldShow: Bool) {
        if shouldShow {
            linkBrowseButton.setTitle("Show Browser", for: UIControlState())
            self.mapView.isHidden = false
            self.webView.isHidden = true
        } else {
            linkBrowseButton.setTitle("Hide Browser", for: UIControlState())
            self.mapView.isHidden = true
            self.webView.isHidden = false
        }
    }

    @IBAction func linkBrowseAction() {
        showHideBrowserButton((linkBrowseButton.currentTitle == "Hide Browser"))
        guard let linkText = linkTextField.text else { return }
        if !currentURLStringIsValid && linkText != "" { triggerWebViewForURLCheck(linkText) }
    }


    fileprivate func manageUIForActiveWebView(_ isActive: Bool) {
        if isActive {
            self.webView.alpha = 0.2
            associatedLinkView.alpha = 0.2
            linkTextField.resignFirstResponder()
            linkTextField.isEnabled = false
        } else {
            self.webView.alpha = 1.0
            linkTextField.isEnabled = true
            self.view.endEditing(true)
            associatedLinkView.alpha = 1.0
        }

    }

    fileprivate func manageUIReadyForSubmit(_ isValid: Bool) {
        currentURLStringIsValid = isValid
        saveButton.isEnabled = isValid
        saveButton.alpha = isValid ? 1.0 : 0.2
    }


    // MARK: -
    // MARK: Web View Management and Link-Checking

    /*
    Attempt to load the user-entered URL string into the web view.
    */
    fileprivate func triggerWebViewForURLCheck(_ rawURLString: String) {
        if var components = URLComponents(string: rawURLString) {
            // in case they didn't enter the 'http://'
            if components.scheme == nil { components.scheme = "http" }
            if let url = components.url {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                let requestObj = NSMutableURLRequest(url: url)
                requestObj.timeoutInterval = 30
                self.webView.loadRequest(requestObj as URLRequest)
                manageUIForActiveWebView(true)
            }
        } else {
            UICommon.errorAlert("URL Validation Failure", message: "That doesn't look like a valid URL", inViewController: self)
        }
    }


    // http://stackoverflow.com/questions/2491410/get-current-url-of-uiwebview/3654403#3654403
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        // don't restore the UI if the error alert dialog is showing
        if (!failedWebViewLoadWithError) { manageUIForActiveWebView(false) }
        if let currentURL = self.webView.request?.url?.absoluteString {
            if currentURL != "about:blank" {
                linkTextField.text = currentURL
                manageUIReadyForSubmit(true)
            } else {
                manageUIReadyForSubmit(false)
            }
        } else {
            manageUIReadyForSubmit(false)
        }
    }

    /* 
        I get inconsistent results from the UIWebView.  Sometimes I see too many unnecessary 
        errors (usually Cancelled and CannotConnectToHost) even thought the web page 
        eventually loads.  And sometimes it hangs without reporting an error or a timeout.
    */
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        let error = error as NSError

        // I think these errors are unnecessarily triggered if the host forwards the request
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled { return }
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCannotConnectToHost { return }

        // Flag to prevent restoration of the UI before the user dismisses the alert
        failedWebViewLoadWithError = true


        UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
        UICommon.errorAlertWithHandler("URL Validation Failure", message: errorStr, inViewController: self, handler: webAlertHandler)
    }

    fileprivate func webAlertHandler(_ action: UIAlertAction!) -> Void {
        self.manageUIForActiveWebView(false)
        self.manageUIReadyForSubmit(false)
        self.failedWebViewLoadWithError = false      // flag that the error has been handled
    }

    fileprivate func clearWebView() {
        if let url = URL(string: "about:blank") {
            let requestObj = URLRequest(url: url)
            self.webView.loadRequest(requestObj)
        }
    }

    // MARK: -
    // MARK: Geocoding

    fileprivate func reportGeocodeError(_ location: String, error: NSError) {
        var errorStr = ""
        if error.code == CLError.Code.locationUnknown.rawValue {
            errorStr = "Location unknown: '\(location)'"
        } else if error.code == CLError.Code.network.rawValue {
            errorStr = "Geocode network connection is not responding"
        } else if error.code == CLError.Code.geocodeFoundNoResult.rawValue {
            errorStr = "No geocode result found for: '\(location)'"
        } else {
            errorStr = "Unknow Core Location error"
        }
        errorStr += "\n\n[\(error.localizedDescription)]"
        UICommon.errorAlert("Geocode Failure", message: errorStr, inViewController: self)
    }


    @IBAction func findOnTheMap() {

        guard let locationName = whereStudyingTextField.text else { /* I don't think this will ever happen */ return }

        findOnMapView.alpha = 0.2
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CLGeocoder().geocodeAddressString(locationName, completionHandler:
            {(placemarks, error) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.findOnMapView.alpha = 1.0
                if let error = error  {
                    self.reportGeocodeError(locationName, error: error as NSError)
                    return
                }
                guard let pmArray = placemarks, pmArray.count > 0 else {
                    // I don't know if this will ever happen
                    UICommon.errorAlert("Geocode Failure", message: "No geocode for \(locationName)", inViewController: self)
                    return
                }
                let pm = pmArray[0]
                guard let placeMarkLoc = pm.location else {
                    // Again, I don't know if this will ever happen
                    UICommon.errorAlert("Geocode Failure", message: "No geocode for \(locationName)", inViewController: self)
                    return
                }
                let user = (UIApplication.shared.delegate as! AppDelegate).currentUser
                user.mapString = locationName
                user.latitude = placeMarkLoc.coordinate.latitude
                user.longitude = placeMarkLoc.coordinate.longitude
                self.mapView.isHidden = false

                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
                let fname = user.firstName == "" ? "?" : user.firstName
                let lname = user.lastName == "" ?  "?" : user.lastName
                annotation.title = "\(fname) \(lname)"
                self.mapView.addAnnotation(annotation)
                let span = MKCoordinateSpanMake(0.1, 0.1)
                let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
                self.swapLinkAndFindView(false)
        })
    }




    // MARK: -
    // MARK: Save Data


    @IBAction func saveData() {
        if !currentURLStringIsValid {
            UICommon.errorAlert("Cannot Save", message: "Cannot save the location without a valid link", inViewController: self)
            return
        }
        guard let linkText = linkTextField.text else {
            // Again, I don't know if this will ever happen
            UICommon.errorAlert("Cannot Save", message: "Cannot save the location without a link", inViewController: self)
            return
        }
        let user = (UIApplication.shared.delegate as! AppDelegate).currentUser
        user.mediaURL = linkText
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.manageUIForActiveWebView(true)
        self.manageUIReadyForSubmit(true)
        NetClient.sharedInstance.postStudentLocation(user, completionHandler: studentLocationClosure)
    }


    func studentLocationClosure(_ data: Data?, response: URLResponse?, error: Error?) -> Void {

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if let error = error {
            UICommon.errorAlertWithHandler("Post API Failure", message: "Failed to post to Parse API student location data\n\n[\(error.localizedDescription)]", inViewController: self, handler: postAlertHandler)
            return
        }
        guard let data = data else {
            UICommon.errorAlertWithHandler("Post API Failure", message: "Failed to post to Parse API student location: not response", inViewController: self, handler: postAlertHandler)
            return
        }

        let parsedDict: [String: AnyObject]?
        do {
            try parsedDict = JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
        } catch let parseError as NSError {
            UICommon.errorAlertWithHandler("Parse API Failure", message: "Could not parse location data returned from Parse\n\n[\(parseError.localizedDescription)]", inViewController: self, handler: postAlertHandler)
            return
        }
        guard let topDict = parsedDict else {
            UICommon.errorAlertWithHandler("Parse API Failure", message: "Failed to received acknowledgment from Parse API", inViewController: self, handler: postAlertHandler)
            return
        }

        let user = (UIApplication.shared.delegate as! AppDelegate).currentUser
        user.updateAfterSave(topDict)
        let newStudent = StudentManager.sharedInstance.appendSavedUser(user)
        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIFICATION_MAP_SCROLL), object: newStudent.annotation)
        DispatchQueue.main.async(execute: {
            self.manageUIForActiveWebView(false)
            self.manageUIReadyForSubmit(true)
        })
        self.dismiss(animated: true, completion: nil)
    }


    fileprivate func postAlertHandler(_ action: UIAlertAction!) -> Void {
        DispatchQueue.main.async(execute: {
            self.manageUIForActiveWebView(false)
            self.manageUIReadyForSubmit(true)
         })
    }


}













