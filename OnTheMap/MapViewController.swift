//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/17/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {



    override func viewDidLoad() {
        super.viewDidLoad()


        let pinButton = UIBarButtonItem(image: UIImage(named: "Pin.pdf"), style: .Plain, target: self, action: Selector("doPin"))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: Selector("doRefresh"))

        let items = [refreshButton, pinButton]
        self.navigationItem.rightBarButtonItems = items

    }


    func doPin() {

    }


    func doRefresh() {

    }
}
