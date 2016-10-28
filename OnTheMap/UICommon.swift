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


    static func setupNavBar(_ callingViewController: UIViewController) -> [UIBarButtonItem] {

        let pinButton = UIBarButtonItem(image: UIImage(named: "Pin.pdf"), style: .plain, target: callingViewController, action: Selector("doPin"))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: callingViewController, action: Selector("doRefresh"))

        return [refreshButton, pinButton]
    }

    static func errorAlertWithHandler(_ title: String, message: String, inViewController: UIViewController, handler: UIAlertActionClosure?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: handler)
        alert.addAction(cancelAction)
        DispatchQueue.main.async(execute: {
            inViewController.present(alert, animated: true, completion: nil)
        })
    }


    static func errorAlert(_ title: String, message: String, inViewController: UIViewController, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        DispatchQueue.main.async(execute: {
            inViewController.present(alert, animated: true, completion: completion)
        })
    }

    static func errorAlert(_ title: String, message: String, inViewController: UIViewController) {
        errorAlert(title, message: message, inViewController: inViewController, completion: nil)
    }

    static func setGradientForView(_ view: UIView) {
        view.backgroundColor = UIColor.clear
        let colorTop = UIColor(red: 0.984, green: 0.605, blue: 0.168, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 0.984, green: 0.438, blue: 0.129, alpha: 1.0).cgColor
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [colorTop, colorBottom]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.frame = view.frame
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    // spacing from here: http://stackoverflow.com/questions/7565645/indent-the-text-in-a-uitextfield
    static func setUpSpacerForTextField(_ field: UITextField) {
        let loginSpacer = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        field.leftViewMode = .always
        field.leftView = loginSpacer
        field.alpha = 0.6
    }
    
}
