//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/17/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {


    @IBOutlet weak var toolBar: UIToolbar!


    override func viewDidLoad() {
        super.viewDidLoad()



        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 48.0, height: 32.0))
        label.textAlignment = .Center
        label.text = "On The Map"
        let buttonTitle = UIBarButtonItem(customView: label)

let logoutBtn = UIBarButtonItem(title: "Logout", style: .Plain, target: self, action: nil)

        let pinBtn = UIBarButtonItem(title: "Pin", style: .Plain, target: self, action: nil)
        pinBtn.image = UIImage(named: "pin")

        let reloadBtn = UIBarButtonItem(title: "Reload", style: .Plain, target: self, action: nil)
let btnArray = [logoutBtn, buttonTitle, pinBtn, reloadBtn]

        toolBar.items = btnArray
    }

}
