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

class LocationManager: NSObject, CLLocationManagerDelegate {

    let manager = CLLocationManager()
    // Warning. Lots of delegates.
    weak var permissionDelegate: LocationPermissionsDelegate?
    weak var locationManagerDelgate: LocationManagerDelegate?
    weak var geoAlertDelegate: GeoNotificationDelegate?
    weak var didNotifyDelegate: didNotifyDelegate?
    
    var geoReminderDelegate: GeoReminderDelegate?
    // The location list datasource
    var dataSource: LocationListDataSource?
    var map: MKMapView?
    var segmentedControl: UISegmentedControl?
    var notificationManager = NotificationManager()
    let context = CoreDataStack().managedObjectContext
    
    var reminder: Reminder? // Is nil when app is in background
    
    var regions = [CLRegion]()
    init(delegate: LocationManagerDelegate?, permissionDelegate: LocationPermissionsDelegate?, map: MKMapView?, geoAlertDelegate: GeoNotificationDelegate?) {
        self.locationManagerDelgate = delegate
        self.permissionDelegate = permissionDelegate
        self.map = map
        self.geoAlertDelegate = geoAlertDelegate
        
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
    // Did change authorization delegate method
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            permissionDelegate?.authorizationSucceeded()
            requestLocation()
        } else {
            permissionDelegate?.authorizationFailedWithStatus(status)
        }
    }
    // DidFail Delegate method
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

        map?.showsUserLocation = true
    }
    
    func startMonitoring(region: CLRegion) {
        manager.startMonitoring(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Region Identifier here in didStart \(region.identifier)")

    }
    
    // This is all mainly the old implementation, DidEnter and DidExit Region, I am using a UNLocationNotificationTrigger now which is more efficient as I've found out first hand.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Did enter region: \(region.identifier)")
        regions.append(region)
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        do {
            let reminders = try context.fetch(fetchRequest)
            for proxyReminder in reminders {
                for _ in regions {
                //    print("Geo Region Identifiers: \(geoRegion.identifier)")
                //    print("Proxy Reminder: \(proxyReminder.text) \(proxyReminder.identifier)")
                    if let proxyIdentifier = proxyReminder.identifier {
                        if proxyIdentifier == region.identifier {
                         //   handleEvent(forRegion: region, reminder: proxyReminder)
                        } else {
                       //     print("Not these: \(proxyIdentifier) & \(region.identifier)")
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Did exit region: \(region.identifier)")
        
        regions.append(region)
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        do {
            let reminders = try context.fetch(fetchRequest)
            for proxyReminder in reminders {
                for geoRegion in regions {
                    print("Geo Region Identifiers: \(geoRegion.identifier)")
              //      print("Proxy Reminder: \(proxyReminder.text) \(proxyReminder.identifier)")
                    if let proxyIdentifier = proxyReminder.identifier {
                        if proxyIdentifier == region.identifier {
                        //    handleEvent(forRegion: region, reminder: proxyReminder)
                        } else {
                            print("Not these: \(proxyIdentifier) & \(region.identifier)")
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
     //   print("Failed to monitor region: \(region), with error: \(error)")
    }
    
    func handleEvent(forRegion region: CLRegion, reminder: Reminder) {
        
        let content = UNMutableNotificationContent()

        let text = reminder.text
        guard let identifier = reminder.identifier else { return }

        content.title = text
        print("The text is here. It worked! \(text)")
        content.sound = .default()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        center.add(request) { (erorr) in
        }
    }
    
}

extension LocationManager: PassReminderDelegate {
    func passReminder(_ reminder: Reminder?) {
        self.reminder = reminder // To hold reminder that was just made in memory, but ends up being nil after monitoring starts and app is in background
    }
}

extension LocationController {
    // How I used to make it work but both didEnter and didExit would make a notification. This function is unused
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
















