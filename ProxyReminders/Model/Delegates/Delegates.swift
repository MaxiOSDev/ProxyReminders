//
//  Delegates.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/21/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
import MapKit

protocol GeoNotificationDelegate: class {
    func showNotification(withTitle title: String, message: String)
}

protocol EventNotificationDelegate: class {
    func addLocationEvent(forReminder reminder: Reminder, forEvent type: EventType, region: CLCircularRegion) -> UNLocationNotificationTrigger?
    func scheduleNewNotification(withReminder reminder: Reminder, locationTrigger trigger: UNLocationNotificationTrigger?)
}

protocol LocationManagerDelegatePassed: class {
    func locationManager(_ manager: LocationManager)
}

protocol MapMonitorDelegate: class {
    // func startMonitoringCoordinates(_ coordinate: Coordinate)
    func startMonitoring(region: CLCircularRegion)
}

protocol GeoRegionDelegateC: class {
    func monitorRegionB(_ region: CLCircularRegion)
}

protocol ReminderCellDelegate: AnyObject {
    func buttonCloseTapped(cell: ReminderCell)
}

protocol SegueDelegate {
    func callSegueFromCell(myData dataObject: AnyObject)
}


protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

protocol GeoRegionDelegate: class {
    func monitorRegion(_ region: CLCircularRegion)
}

protocol GeoRegionDelegateB: class {
    func monitorRegionB(_ region: CLCircularRegion)
}


protocol GeoReminderDelegate: class {
    var latitude: Double? { get }
    var longitude: Double? { get }
    var eventType: EventType? { get }
    var identifier: String? { get set }
    var radius: Double? { get }
    var location: String? { get }
}


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

protocol PassReminderDelegate: class {
    func passReminder(_ reminder: Reminder?)
}






