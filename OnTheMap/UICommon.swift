//
//  UICommon.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/17/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation
import UIKit

public typealias UIAlertActionClosure = (UIAlertAction!) -> Void


struct UICommon {


    static func setupNavBar(callingViewController: UIViewController) -> [UIBarButtonItem] {

        let pinButton = UIBarButtonItem(image: UIImage(named: "Pin.pdf"), style: .Plain, target: callingViewController, action: Selector("doPin"))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: callingViewController, action: Selector("doRefresh"))

        return [refreshButton, pinButton]
    }

    static func errorAlertWithHandler(title: String, message: String, inViewController: UIViewController, handler: UIAlertActionClosure?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: handler)
        alert.addAction(cancelAction)
        dispatch_async(dispatch_get_main_queue(), {
            inViewController.presentViewController(alert, animated: true, completion: nil)
        })
    }


    static func errorAlert(title: String, message: String, inViewController: UIViewController, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        dispatch_async(dispatch_get_main_queue(), {
            inViewController.presentViewController(alert, animated: true, completion: completion)
        })
    }

    static func errorAlert(title: String, message: String, inViewController: UIViewController) {
        errorAlert(title, message: message, inViewController: inViewController, completion: nil)
    }

    static func setGradientForView(view: UIView) {
        view.backgroundColor = UIColor.clearColor()
        let colorTop = UIColor(red: 0.984, green: 0.605, blue: 0.168, alpha: 1.0).CGColor
        let colorBottom = UIColor(red: 0.984, green: 0.438, blue: 0.129, alpha: 1.0).CGColor
        var backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [colorTop, colorBottom]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.frame = view.frame
        view.layer.insertSublayer(backgroundGradient, atIndex: 0)
    }

    // spacing from here: http://stackoverflow.com/questions/7565645/indent-the-text-in-a-uitextfield
    static func setUpSpacerForTextField(field: UITextField) {
        let loginSpacer = UIView(frame: CGRectMake(0, 0, 10, 10))
        field.leftViewMode = .Always
        field.leftView = loginSpacer
        field.alpha = 0.6
    }
    
}