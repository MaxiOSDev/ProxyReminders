//
//  LocationController.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewDelegate: class {
    func showMap()
    func hideMap()
}

class LocationController: UIViewController, MapViewDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showMap() {
        
    }
    
    func hideMap() {
        
    }

}
