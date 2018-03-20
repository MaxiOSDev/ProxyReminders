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
    func showMap(for view: UIView)
    func hideMap()
}

class LocationController: UIViewController, MapViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerConstraint: NSLayoutConstraint!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    lazy var dataSource: LocationListDataSource = {
        return LocationListDataSource(tableView: tableView, searchController: searchController, mapView: mapView, container: mapContainerView)
    }()
    
    lazy var locationManger: LocationManager = {
       return LocationManager(delegate: dataSource, permissionDelegate: dataSource, map: mapView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        tableView.tableHeaderView = searchController.searchBar
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = dataSource
        mapView.delegate = dataSource
        dataSource.delegate = self
        definesPresentationContext = true
        requestLocationsPermissions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func setProximity(_ sender: Any) {
        
    }
    
    @objc func requestLocationsPermissions() {
        do {
            try locationManger.requestLocationAuthorization()
            locationManger.requestLocation()
        } catch LocationError.disallowedByUser {
            print("Disallowed by User")
        } catch let error {
            print("Location Authorization Error: \(error.localizedDescription)")
        }
    }
    
    
    func showMap(for view: UIView) {
        print("Show map called")
        containerConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func hideMap() {
        print("Hide map called")
        containerConstraint.constant = 274
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

}












