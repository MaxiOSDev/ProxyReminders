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


class LocationController: UIViewController, MapViewDelegate, GeoIdentifierA, GeoSaveB, GeoReminderDelegate, GeoRegionDelegate {
  
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerConstraint: NSLayoutConstraint!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    // Lazily loaded dataSource that takes a search controller, mapview, mapview container, and the segmeneted control
    lazy var dataSource: LocationListDataSource = {
        return LocationListDataSource(tableView: tableView, searchController: searchController, mapView: mapView, container: mapContainerView, control: segmentedControl)
    }()
    
    // The lazily loaded location manager as taught. Honestly I like having it lazily loaded instead of just having everything in here or the datasource.
    lazy var locationManger: LocationManager = {
        return LocationManager(delegate: dataSource, permissionDelegate: dataSource, map: mapView, geoAlertDelegate: nil)
    }()
    
    // Bunch of delegetes. Yes I know, lots of delegates.
    weak var geoSaveDelegate: GeoSave?
    weak var geoIdentifier: GeoIdentifierB?
    weak var reminderLocationDelegate: SavedReminderLocation?
    weak var eventNotificationDelegate: EventNotificationDelegate?
    weak var geoRegionDelegate: GeoRegionDelegateB?
    weak var locationManagerPassed: LocationManagerDelegatePassed?
    weak var locationManagerPassedB: LocationManagerDelegatePassedB?
    // The Notification Manager
    let notificationManger = NotificationManager()
    
    // Stored Properties that will hold the data from the datasource that will eventually be passed to the detail vc.
    var eventType: EventType?
    var latitude: Double?
    var longitude: Double?
    var identifier: String?
    var radius: Double?
    var reminder: Reminder?
    var location: String?
    var geoRegion: CLCircularRegion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Necessary tableview and search bar stuff
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        tableView.tableHeaderView = searchController.searchBar
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = dataSource
        
        // MapView delegate is within the datasource
        mapView.delegate = dataSource
        
        // Assinging all of these delegetes to self
        dataSource.delegate = self
        dataSource.geoSaveB = self
        locationManger.geoReminderDelegate = self
        dataSource.geoIdentifier = self

        dataSource.monitorRegion = self
        
        definesPresentationContext = true
        // Request Locations permission
        requestLocationsPermissions()
        dataSource.savedLocation(for: reminder)
        locationManagerPassedB?.locationManager(locationManger)
        segmentedControl.selectedSegmentIndex = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setProximityDefault() {
        //dataSource.circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.4)
        // Basically send that data to the detail VC.
        geoSaveDelegate?.dataSaved(latitude: latitude, longitude: longitude, eventType: .onEntry, radius: 50.00, location: location)
        geoIdentifier?.saveIdentifier(identifier: identifier)
        geoRegionDelegate?.monitorRegionB(geoRegion!)
        locationManagerPassed?.locationManager(locationManger)
        
        // And a print statment to see that all worked out
        print("In set proximity \(latitude) \(longitude) \(eventType?.rawValue) \(radius) \(location)")
    }
    
    // The segmentedControl's IBAction. There is alot going on in here.
    @IBAction func setProximity(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            // The chanign of the fill color back to blue
            dataSource.circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.4)
            // Basically send that data to the detail VC.
            geoSaveDelegate?.dataSaved(latitude: latitude, longitude: longitude, eventType: .onEntry, radius: 50.00, location: location)
            geoIdentifier?.saveIdentifier(identifier: identifier)
            geoRegionDelegate?.monitorRegionB(geoRegion!)
            locationManagerPassed?.locationManager(locationManger)
            
            // And a print statment to see that all worked out
            print("In set proximity \(latitude) \(longitude) \(eventType?.rawValue) \(radius) \(location)")
        } else {
            // Make the fill color clear, but the stroke color is the same.
            dataSource.circleRenderer.fillColor = UIColor.clear
            // send the data for use in the detial vc
            geoSaveDelegate?.dataSaved(latitude: latitude, longitude: longitude, eventType: .onExit, radius: 50.00, location: location)
            geoIdentifier?.saveIdentifier(identifier: identifier)
            geoRegionDelegate?.monitorRegionB(geoRegion!)
            locationManagerPassed?.locationManager(locationManger)
            
            print("In set proximity \(latitude) \(longitude) \(eventType?.rawValue) \(radius) \(location)")
        }
    }
    
    // Things learnt from Pasan.
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
    
    // The delegate methods. How I show my map and hide
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
    
    // How I assign the data from the datasource to these properties which will be sent to the detial vc.
    func saveIdentifier(identifier: String?) {
        self.identifier = identifier
        
    }
    
    func dataSaved(latitude: Double?, longitude: Double?, radius: Double?, location: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.location = location
        setProximityDefault()
    }
    
    func monitorRegion(_ region: CLCircularRegion) {
        print("Region that was passed \(region)")
        self.geoRegion = region
        
        print("The changed GeoRegion \(geoRegion)")
    }

}












