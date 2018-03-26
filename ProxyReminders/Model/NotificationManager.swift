//
//  NotificationManager.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/20/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import Foundation
import UserNotifications
import CoreLocation

class NotificationManager: GeoRegionDelegateC, LocationManagerDelegatePassed {
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    var geoRegion: CLCircularRegion?
    var locationManager: LocationManager?
    
    func scheduleNewNotification(withReminder reminder: Reminder, locationTrigger trigger: UNLocationNotificationTrigger?) {
        //  let text = reminder.text
        //  print("Reminder Identifier \(reminder.identifier)")
        //  guard let identifier = reminder.identifier else { return }
        // I would use the addLocationEvent method to make a UNLocationNotificationTrigger and then pass it through here.
        
        guard let notificationTrigger = trigger else { return }
        let identifier = notificationTrigger.region.identifier
        let content = UNMutableNotificationContent()
        content.title = reminder.text // Just for testing
        content.sound = .default()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: notificationTrigger)
        
        notificationCenter.add(request)
        
    }
    
    func addLocationEvent(forReminder reminder: Reminder, forEvent type: EventType) -> UNLocationNotificationTrigger? {
           guard let latitude = reminder.latitude as? Double else { return nil }
            guard let longitude = reminder.longitude as? Double else { return nil }
            guard let regionIdentifier = reminder.identifier else { return nil }
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = CLCircularRegion(center: center, radius: 50.00, identifier: regionIdentifier)
        
        print("Region identifier inside the notification manager: \(region.identifier)")

        print("Reminder identifier in the notification manager: \(reminder.identifier)")

        // My idea was to switch if the region notifys by type. But it seems to not be working properly, both didEnter and didExit go off.
        switch type {
        case .onEntry:
            region.notifyOnExit = false
            region.notifyOnEntry = true
        case .onExit:
            region.notifyOnExit = true
            region.notifyOnEntry = false
        }

        return UNLocationNotificationTrigger(region: region, repeats: true)
    }
    // Some delegate methods.
    func monitorRegionB(_ region: CLCircularRegion) {
        self.geoRegion = region
    }
    
    func locationManager(_ manager: LocationManager) {
        self.locationManager = manager
    }
    
}
