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
    // MARK: properties
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

    // MARK: -
    // MARK: loading
    override func viewDidLoad() {
        super.viewDidLoad()
        //testValidURLs()
        self.findOnMapView.alpha = 1.0
        self.findOnMapView.backgroundColor = UIColor.clearColor()
        self.mapView.hidden = true
        self.webView.hidden = true
        self.webView.delegate = self
        self.associatedLinkView.backgroundColor = UIColor.clearColor()
        self.swapViewsFindIsActive(true)
        manageFindButton(false)
        UICommon.setGradientForView(self.view)
        UICommon.setUpSpacerForTextField(whereStudyingTextField)
        linkTextField.delegate = self
        whereStudyingTextField.delegate = self
        whereStudyingTextField.becomeFirstResponder()

    }


    // MARK: -
    // MARK: UI

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {
            if textField != whereStudyingTextField { return true }

            var newText: NSString = whereStudyingTextField.text
            newText = newText.stringByReplacingCharactersInRange(range, withString: string)
            manageFindButton(newText.length > 0)
            return true
    }


    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == linkTextField {
            if self.webView.hidden { linkBrowseAction() }
            checkValidURLString(linkTextField.text)
        } else if textField == whereStudyingTextField  {
            if findOnMapButton.enabled { findOnTheMap() }
        }
        return true
    }

    private func manageFindButton(enable: Bool) {
        findOnMapButton.enabled = enable
        if enable {findOnMapButton.alpha = 1.0 } else { findOnMapButton.alpha = 0.2 }
    }

    private func swapViewsFindIsActive(enableFind: Bool) {
        if enableFind {
            self.findOnMapView.hidden = false
            self.associatedLinkView.hidden = true
        } else {
            self.findOnMapView.hidden = true
            self.associatedLinkView.hidden = false
            if linkTextField.text == "" { linkTextField.text = "http://" }
            linkTextField.becomeFirstResponder()
        }
    }


    @IBAction func linkBrowseAction() {
        if linkBrowseButton.currentTitle == "Hide Browser" {
            linkBrowseButton.setTitle("Show Browser", forState: .Normal)
            self.mapView.hidden = false
            self.webView.hidden = true
        } else {
            linkTextField.becomeFirstResponder()
            linkBrowseButton.setTitle("Hide Browser", forState: .Normal)
            self.mapView.hidden = true
            self.webView.hidden = false
         }
    }


    private func checkValidURLString(rawURLString: String) {

        if let components = NSURLComponents(string: rawURLString) {
            // in case they didn't enter the 'http://'
            if components.scheme == nil { components.scheme = "http" }
            if let url = components.URL {
                let requestObj = NSURLRequest(URL: url)
                self.webView.loadRequest(requestObj)
                return
            }
        }
        currentURLStringIsValid = false
    }


    // http://stackoverflow.com/questions/2491410/get-current-url-of-uiwebview/3654403#3654403
    func webViewDidFinishLoad(webView: UIWebView) {
        if let currentURL = self.webView.request?.URL?.absoluteString {
            if currentURL != "about:blank" {
                linkTextField.text = currentURL
                currentURLStringIsValid = true
            } else {
                linkTextField.text = "http://"
                currentURLStringIsValid = false
            }
        } else {
            currentURLStringIsValid = false
        }
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {

        if error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorNetworkConnectionLost {
            let errorStr = "Not connected to the internet\n\n\(error.localizedDescription)"
            UICommon.errorAlert("URL Validation Failure", message: errorStr, inViewController: self)
        } else if error.code == NSURLErrorCannotFindHost {
            let errorStr = "\(error.localizedDescription)"
            UICommon.errorAlert("URL Validation Failure", message: errorStr, inViewController: self)
        }
        if let currentURL = self.webView.request?.URL?.absoluteString {
            println("didFailLoadWithError=[\(error.code)]\n\(error.localizedDescription)\n\(currentURL)")
        } else {
            println("didFailLoadWithError=[\(error.code)]\n\(error.localizedDescription)")
        }
        /*
        If you load a valid URL, then type in another invalid URL, the web view
        does not redraw to erase the previous valid page.  So, force it to "about:blank"
        */
        currentURLStringIsValid = false
        clearWebView()
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
//                    println("name=\(pm.name)")
//                    println("addr=\(pm.addressDictionary)")
//                    println("post=\(pm.postalCode)")
//                    println("reg=\(pm.region)")
//                    println("lat=\(pm.location.coordinate.latitude)")
//                    println("long=\(pm.location.coordinate.longitude)")

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
                    self.swapViewsFindIsActive(false)
            })

        }
    }


    // MARK: -
    // MARK: URL validator and its tester

    /*
    http://stackoverflow.com/questions/1471201/how-to-validate-an-url-on-the-iphone
    http://stackoverflow.com/questions/24345928/swift-using-nsdatadetectors
    */
//    private func getValidURL(rawURLString: String) -> String? {
//        var length = count(rawURLString)
//        if length <= 0 { return nil }
//
//        var urlString = rawURLString.lowercaseString
//        if !urlString.hasPrefix("http") { urlString = "http://" + rawURLString }
//        length = count(urlString)
//
//        var error: NSError? = nil
//        let dataDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue, error: &error)
//        if error != nil || dataDetector == nil {
//            return nil
//        }
//        let range = NSMakeRange(0, length)
//        let notFoundRange = NSMakeRange(NSNotFound, 0)
//        let linkRange = dataDetector!.rangeOfFirstMatchInString(urlString, options: .Anchored, range: range)
//        if !NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(linkRange, range) { return urlString }
//        return nil
//    }


/* Test Results
    www.o2l.com=Optional("http://www.o2l.com")
    wwwo2lcom=Optional("http://wwwo2lcom")
    http://www.o2l.com=Optional("http://www.o2l.com")
    =nil
    www.o2l.com/aaaaa=Optional("http://www.o2l.com/aaaaa")
    o2l.com=Optional("http://o2l.com")
    .com=Optional("http://.com")
    .=nil
    http=nil
    http:=nil
    http:/=nil
    http://=nil
    http://www=Optional("http://www")
    http.s://www.gmail.com=Optional("http.s://www.gmail.com")
    https:.//gmailcom=nil
    https://gmail.me.=nil
    https://www.gmail.me.com.com.com.com=Optional("https://www.gmail.me.com.com.com.com")
    http:/./ww-w.wowone.com=nil
    http://.www.wowone=Optional("http://.www.wowone")
    http://www.wow-one.com=Optional("http://www.wow-one.com")
    http://k=Optional("http://k")
    http:\gmail.com=nil
    youtube.com/watch?v=LwE99t-kg7E=Optional("http://youtube.com/watch?v=LwE99t-kg7E")
    'https://'google.com=Optional("http://\'https://\'google.com")
    fake://0=Optional("http://fake://0")

*/

//    private func testValidURLs() {
//        var s = ""
//        s = "www.o2l.com"; println("\(s)=\(getValidURL(s))")
//        s = "wwwo2lcom"; println("\(s)=\(getValidURL(s))")
//        s = "http://www.o2l.com"; println("\(s)=\(getValidURL(s))")
//        s = ""; println("\(s)=\(getValidURL(s))")
//        s = "www.o2l.com/aaaaa"; println("\(s)=\(getValidURL(s))")
//        s = "o2l.com"; println("\(s)=\(getValidURL(s))")
//        s = ".com"; println("\(s)=\(getValidURL(s))")
//        s = "."; println("\(s)=\(getValidURL(s))")
//        s = "http"; println("\(s)=\(getValidURL(s))")
//        s = "http:"; println("\(s)=\(getValidURL(s))")
//        s = "http:/"; println("\(s)=\(getValidURL(s))")
//        s = "http://"; println("\(s)=\(getValidURL(s))")
//        s = "http://www"; println("\(s)=\(getValidURL(s))")
//        //--
//        s = "http.s://www.gmail.com"; println("\(s)=\(getValidURL(s))")
//        s = "https:.//gmailcom"; println("\(s)=\(getValidURL(s))")
//        s = "https://gmail.me."; println("\(s)=\(getValidURL(s))")
//        s = "https://www.gmail.me.com.com.com.com"; println("\(s)=\(getValidURL(s))")
//        s = "http:/./ww-w.wowone.com"; println("\(s)=\(getValidURL(s))")
//        s = "http://.www.wowone"; println("\(s)=\(getValidURL(s))")
//        s = "http://www.wow-one.com"; println("\(s)=\(getValidURL(s))")
//        s = "http://k"; println("\(s)=\(getValidURL(s))")
//        s = "http:\\gmail.com"; println("\(s)=\(getValidURL(s))")
//        s = "youtube.com/watch?v=LwE99t-kg7E"; println("\(s)=\(getValidURL(s))")
//        s = "'https://'google.com"; println("\(s)=\(getValidURL(s))")
//        s = "fake://0"; println("\(s)=\(getValidURL(s))")
//    }




    // MARK: -
    // MARK: Save Data


    @IBAction func saveData() {
        //      if let urlString = getValidURL(linkTextField.text) {
        if currentURLStringIsValid {
        } else {
            UICommon.errorAlert("Cannot Save", message: "Cannot save the location without a valid link", inViewController: self)
            return
        }
    }

}

