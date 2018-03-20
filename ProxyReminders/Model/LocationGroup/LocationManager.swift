//
//  LocationManager.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/20/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import MapKit

struct Coordinate {
    let latitude: Double
    let longitude: Double
}

extension Coordinate {
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}

enum LocationError: Error {
    case unknownError
    case disallowedByUser
    case unableToFindLocation
}

protocol LocationPermissionsDelegate: class {
    func authorizationSucceeded()
    func authorizationFailedWithStatus(_ status: CLAuthorizationStatus)
}

protocol LocationManagerDelegate: class {
    func obtainedCoordinates(_ coordinate: Coordinate)
    func failedWithError(_ error: LocationError)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    weak var permissionDelegate: LocationPermissionsDelegate?
    weak var locationManagerDelgate: LocationManagerDelegate?
    var dataSource: LocationListDataSource?
    var map: MKMapView?
    var segmentedControl: UISegmentedControl?
    
    init(delegate: LocationManagerDelegate?, permissionDelegate: LocationPermissionsDelegate?, map: MKMapView?) {
        self.locationManagerDelgate = delegate
        self.permissionDelegate = permissionDelegate
        self.map = map
        super.init()
        manager.delegate = self
    }
    
    static var isAuthorized: Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways: return true
        default: return false
        }
    }
    
    func requestLocationAuthorization() throws {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        if authorizationStatus == .restricted || authorizationStatus == .denied {
            throw LocationError.disallowedByUser
        } else if authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
            manager.desiredAccuracy = kCLLocationAccuracyBest
            
        } else {
            return
        }
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            permissionDelegate?.authorizationSucceeded()
            requestLocation()
        } else {
            permissionDelegate?.authorizationFailedWithStatus(status)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let error = error as? CLError else { locationManagerDelgate?.failedWithError(.unknownError)
            return }
        
        switch error.code {
        case .locationUnknown, .network: locationManagerDelgate?.failedWithError(.unableToFindLocation)
        case .denied: locationManagerDelgate?.failedWithError(.disallowedByUser)
        default: return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { locationManagerDelgate?.failedWithError(.unableToFindLocation)
            return
        }
        let coordinate = Coordinate(location: location)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        map?.setRegion(region, animated: true)
        
        locationManagerDelgate?.obtainedCoordinates(coordinate)
        manager.stopUpdatingLocation()
        map?.showsUserLocation = true
    }
    
    func startMonitoringCoordinates(_ coordinate: Coordinate) {
        let circleRegionCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let circleRegion = CLCircularRegion(center: circleRegionCoordinate, radius: 50.00, identifier: "RandomIdentifier")
        self.map?.removeOverlays((map?.overlays)!)
        circleRegion.notifyOnEntry = true
        circleRegion.notifyOnExit = true
        
        manager.startMonitoring(for: circleRegion)
        let circle = MKCircle(center: circleRegionCoordinate, radius: circleRegion.radius)
        self.map?.add(circle)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Monitoring Started")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Region Entered")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Region Exited")
    }
    
    
    
}















