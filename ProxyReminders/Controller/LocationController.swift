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
import UserNotifications

protocol MapViewDelegate: class {
    func showMap(for view: UIView)
    func hideMap()
}

protocol GeoSave: class {
    func dataSaved(latitude: Double?, longitude: Double?, eventType: EventType?, radius: Double?, location: String?)
}

protocol GeoSaveB: class {
    func dataSaved(latitude: Double?, longitude: Double?, radius: Double?, location: String?)
}

protocol GeoIdentifierA: class {
    func saveIdentifier(identifier: String?)
}

protocol GeoIdentifierB: class {
    func saveIdentifier(identifier: String?)
}

protocol SavedReminderLocation: class {
    func savedLocation(for reminder: Reminder?)
}

class LocationController: UIViewController, MapViewDelegate, GeoIdentifierA, GeoSaveB, GeoReminderDelegate {
  
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerConstraint: NSLayoutConstraint!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    lazy var dataSource: LocationListDataSource = {
        return LocationListDataSource(tableView: tableView, searchController: searchController, mapView: mapView, container: mapContainerView, control: segmentedControl)
    }()
    
    lazy var locationManger: LocationManager = {
       return LocationManager(delegate: dataSource, permissionDelegate: dataSource, map: mapView)
    }()
    
    weak var geoSaveDelegate: GeoSave?
    weak var geoIdentifier: GeoIdentifierB?
    weak var reminderLocationDelegate: SavedReminderLocation?
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    var eventType: EventType?
    var latitude: Double?
    var longitude: Double?
    var identifier: String?
    var radius: Double?
    var reminder: Reminder?
    var location: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            
        }
        
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        tableView.tableHeaderView = searchController.searchBar
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = dataSource
        mapView.delegate = dataSource
        dataSource.monitorDelegate = locationManger
        dataSource.delegate = self
        dataSource.geoSaveB = self
        locationManger.geoReminderDelegate = self
        locationManger.geoIdentifier = self
        locationManger.geoAlertDelegate = self
        definesPresentationContext = true
        requestLocationsPermissions()
        dataSource.savedLocation(for: reminder)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func setProximity(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            dataSource.circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.4)
            geoSaveDelegate?.dataSaved(latitude: latitude, longitude: longitude, eventType: .onEntry, radius: 50.00, location: location)
            geoIdentifier?.saveIdentifier(identifier: identifier)
            print("In set proximity \(latitude) \(longitude) \(eventType?.rawValue) \(radius) \(location)")
        } else {
            dataSource.circleRenderer.fillColor = UIColor.clear
            geoSaveDelegate?.dataSaved(latitude: latitude, longitude: longitude, eventType: .onExit, radius: 50.00, location: location)
            geoIdentifier?.saveIdentifier(identifier: identifier)
            print("In set proximity \(latitude) \(longitude) \(eventType?.rawValue) \(radius) \(location)")
        }
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
    
    func saveIdentifier(identifier: String?) {
        self.identifier = identifier
    }
    
    func dataSaved(latitude: Double?, longitude: Double?, radius: Double?, location: String?) {
        self.latitude = latitude
        print(latitude)
        print(longitude)
        print(radius)
        print(location)
        self.longitude = longitude
        self.radius = radius
        self.location = location
    }

}












