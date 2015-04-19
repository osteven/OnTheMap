//
//  UICommon.swift
//  OnTheMap
//
//  Created by Steven O'Toole on 4/17/15.
//  Copyright (c) 2015 Steven O'Toole. All rights reserved.
//

import Foundation
import UIKit

struct UICommon {




    static func setupNavBar(callingViewController: UIViewController) -> [UIBarButtonItem] {

        let pinButton = UIBarButtonItem(image: UIImage(named: "Pin.pdf"), style: .Plain, target: callingViewController, action: Selector("doPin"))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: callingViewController, action: Selector("doRefresh"))

        return [refreshButton, pinButton]
    }



    
}