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
import UserNotifications

protocol GeoNotificationDelegate: class {
    func showNotification(withTitle title: String, message: String)
    func addLocationEvent(forReminder reminder: Reminder, forEvent type: EventType) -> UNLocationNotificationTrigger?
    func scheduleNewNotification(withReminder reminder: Reminder, locationTrigger trigger: UNLocationNotificationTrigger?)
}

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

protocol MapMonitorDelegate: class {
    func startMonitoringCoordinates(_ coordinate: Coordinate)
}

class LocationManager: NSObject, CLLocationManagerDelegate, MapMonitorDelegate {
    private let manager = CLLocationManager()
    weak var permissionDelegate: LocationPermissionsDelegate?
    weak var locationManagerDelgate: LocationManagerDelegate?
    weak var geoIdentifier: GeoIdentifierA?
    weak var geoAlertDelegate: GeoNotificationDelegate?
    var geoReminderDelegate: GeoReminderDelegate?
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
        
        let identifier = UUID().uuidString.description
        print("Identifier within startMonitoring \(identifier)")
        geoReminderDelegate?.identifier = identifier
        geoIdentifier?.saveIdentifier(identifier: identifier)
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

        //    geoAlertDelegate?.showNotification(withTitle: "Entered Region", message: "You just entered the region you placed")




    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Region Exited")

         //   geoAlertDelegate?.showNotification(withTitle: "Exited Region", message: "You just exited the region you placed")
        



    }
    


}

extension LocationController: GeoNotificationDelegate {
    func scheduleNewNotification(withReminder reminder: Reminder, locationTrigger trigger: UNLocationNotificationTrigger?) {
        let text = reminder.text
        guard let identifier = self.identifier else { return }
        guard let notificationTrigger = trigger else { return }
        
        let content = UNMutableNotificationContent()
        content.body = text
        content.sound = .default()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: notificationTrigger)
        
        notificationCenter.add(request)
    }
    
    func addLocationEvent(forReminder reminder: Reminder, forEvent type: EventType) -> UNLocationNotificationTrigger? {
        guard let latitude = self.latitude else { return nil }
        guard let longitude = self.longitude else { return nil}
        guard let regionIdentifier = identifier else { return nil }
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: 50.00, identifier: regionIdentifier)
        
        switch type {
        case .onEntry:
            region.notifyOnExit = false
            region.notifyOnEntry = true
        case .onExit:
            region.notifyOnExit = true
            region.notifyOnEntry = true
        }
        
        return UNLocationNotificationTrigger(region: region, repeats: false)
    }
    
    func showNotification(withTitle title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        content.sound = .default()
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            
        }
    }
}














