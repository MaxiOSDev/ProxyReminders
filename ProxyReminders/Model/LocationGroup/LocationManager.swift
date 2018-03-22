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
import CoreData

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

class LocationManager: NSObject, CLLocationManagerDelegate { // MapMonitorDelegate

    
    let manager = CLLocationManager()
    weak var permissionDelegate: LocationPermissionsDelegate?
    weak var locationManagerDelgate: LocationManagerDelegate?

    weak var geoAlertDelegate: GeoNotificationDelegate?
    var geoReminderDelegate: GeoReminderDelegate?
    var dataSource: LocationListDataSource?
    var map: MKMapView?
    var segmentedControl: UISegmentedControl?
    var notificationManager = NotificationManager()
    
    var locationTrigger: UNLocationNotificationTrigger?
    var reminder: Reminder?
    
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
            manager.allowsBackgroundLocationUpdates = true
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

    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Monitoring Started")
        print("Region identifier inside the location manager after monitoring: \(region.identifier)")
    }

    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Region Entered: \(region.identifier)")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Region Exited: \(region.identifier)")

    }

}

extension LocationManager: PassReminderDelegate {
    func passReminder(_ reminder: Reminder?) {
        self.reminder = reminder

    }
}

extension LocationController: GeoNotificationDelegate {

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


class NotificationManager: GeoRegionDelegateC, LocationManagerDelegatePassed {

    let notificationCenter = UNUserNotificationCenter.current()
    
    var geoRegion: CLCircularRegion?
    var locationManager: LocationManager?
    
    func scheduleNewNotification(withReminder reminder: Reminder, locationTrigger trigger: UNLocationNotificationTrigger?) {
        let text = reminder.text
     //   print("Reminder Identifier \(reminder.identifier)")
 //       guard let identifier = reminder.identifier else { return }
        guard let notificationTrigger = trigger else { return }
        
        let content = UNMutableNotificationContent()
        content.body = "back to apple"
        content.sound = .default()
        let request = UNNotificationRequest(identifier: "identifier", content: content, trigger: notificationTrigger)
        
        notificationCenter.add(request)
        
    }

    func addLocationEvent(forReminder reminder: Reminder, forEvent type: EventType) -> UNLocationNotificationTrigger? {
     //   guard let latitude = reminder.latitude as? Double else { return nil }
    //    guard let longitude = reminder.longitude as? Double else { return nil }
   //    guard let regionIdentifier = reminder.identifier else { return nil }
    //    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    //    let region = CLCircularRegion(center: center, radius: 50.00, identifier: regionIdentifier)
        
        print("Manager \(locationManager)")
        
        let region = geoRegion!
        print("Region identifier inside the notification manager: \(region.identifier)")
        locationManager?.manager.startMonitoring(for: region)
        print("Reminder identifier: \(reminder.identifier)")
        print("Region \(region)")
        switch type {
        case .onEntry:
            region.notifyOnExit = false
            region.notifyOnEntry = true
        case .onExit:
            region.notifyOnExit = true
            region.notifyOnEntry = false
        }
        
        return UNLocationNotificationTrigger(region: region, repeats: false)
    }
    
    func monitorRegionB(_ region: CLCircularRegion) {
        self.geoRegion = region
    }
    
    func locationManager(_ manager: LocationManager) {
        self.locationManager = manager
    }
    
}














