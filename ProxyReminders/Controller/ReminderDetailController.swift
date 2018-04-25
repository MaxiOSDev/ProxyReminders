//
//  ReminderDetailController.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications

class ReminderDetailController: UITableViewController, GeoSave, GeoIdentifierB, GeoRegionDelegateB {

    // IB Outlets
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // Stored properties
    var context: NSManagedObjectContext?
    var reminder: Reminder?
    var geoDelegate: GeoReminderDelegate?
    weak var geoRegionDelegateC: GeoRegionDelegateC?
    
    // Propeties that hold the data from the LocationController and also Locaiton Datasource
    // so the reminder can be saved with this data. Yes I used a ton of delegates. I know.
    var latitude: Double?
    var longitude: Double?
    var eventType: EventType?
    var identifier: String?
    var radius: Double?
    var location: String?
    var textViewText: String?
    var geoRegion: CLCircularRegion?
    
    lazy var locationManager: LocationManager = {
      //  return LocationManager(delegate: self, permissionDelegate: self, map: nil, geoAlertDelegate: self)
        return LocationManager(delegate: self, permissionDelegate: self, map: nil, geoAlertDelegate: nil)
    }()

    // My notification manager
    var notificationManager = NotificationManager()
    var notificationCenter = UNUserNotificationCenter.current()
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0 , 0)
        tableView.tableFooterView = UIView(frame: .zero)
        print("Reminder text \(reminder?.text)")
        print("Reminder identifier: \(reminder?.identifier)")

        geoRegionDelegateC = notificationManager // Delegate for region, the implementation is in the notification manager.
        configureView()
        
        if reminder?.identifier == nil {
            locationSwitch.isOn = false
            locationNameLabel.text = ""
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // This either edits the remidner or saves a new one.
    @IBAction func saveReminder(_ sender: Any) {
        saveReminder()
        dismiss(animated: true, completion: nil) // Dismisses modally presented view when saved.
    }

    
    // Delegate methods so my properties arn't nil, and can be saved into core data
    func dataSaved(latitude: Double?, longitude: Double?, eventType: EventType?, radius: Double?, location: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.eventType = eventType
        self.radius = radius
        self.location = location
    }
    
    func saveIdentifier(identifier: String?) {
        self.identifier = identifier
    }
    
    func monitorRegionB(_ region: CLCircularRegion) {
        self.geoRegion = region
    }
    
    func saveReminder() {
        guard let text = textView.text, !textView.text.isEmpty else { return }
        
        if self.reminder != nil {
            if let oldReminder = self.reminder {
                oldReminder.text = text
                oldReminder.latitude = latitude as NSNumber?
                oldReminder.longitude = longitude as NSNumber?
                oldReminder.radius = radius as NSNumber?
                
                if geoRegion?.identifier != nil {
                    // Deletes old notifcaiton so a new one can be made in its place with reminders identifier being the same as the geo region and notification.
                    print("Before identifier changed: \(oldReminder.identifier)")
                    notificationCenter.getPendingNotificationRequests { (notificationRequests) in
                        var identifiers: [String] = []
                        for notification: UNNotificationRequest in notificationRequests {
                            if oldReminder.identifier != nil {
                                if notification.identifier == oldReminder.identifier! {
                                    identifiers.append(notification.identifier)
                                    
                                }
                                print("Notification identifier: \(notification.identifier), Reminder identifier: \(oldReminder.identifier)")
                            }
                        }
                        
                        print("Identifiers here: \(identifiers)")
                        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
                        oldReminder.identifier = self.geoRegion?.identifier
                    }
                    
                    print("After identifier changed: \(oldReminder.identifier)")
                } else {
                    if !locationSwitch.isOn {
                        oldReminder.identifier = nil
                    }
                    
                }
                
                
                oldReminder.eventType = eventType?.rawValue
                oldReminder.location = location
                // Location is basically the name so I can place it inside my location name label with string interpolation.
                context?.saveChanges() // Save those changes!
                if geoRegion?.identifier != nil {
                    geoRegionDelegateC?.monitorRegionB(geoRegion!)
                    
                    let trigger = notificationManager.addLocationEvent(forReminder: oldReminder, forEvent: EventType(rawValue: oldReminder.eventType!)!)
                    notificationManager.scheduleNewNotification(withReminder: oldReminder, locationTrigger: trigger)
                    
                    notificationCenter.getPendingNotificationRequests { (notificationRequests) in
                        print("All notifications requests here: \(notificationRequests)\n")
                    }
                    
                } else {
                    
                    if locationSwitch.isOn {
                        if oldReminder.identifier != nil {
                            notificationCenter.getPendingNotificationRequests { (notificationRequests) in
                                var identifiers: [String] = []
                                
                                for notification: UNNotificationRequest in notificationRequests {
                                    if notification.identifier == oldReminder.identifier! {
                                        
                                        identifiers.append(notification.identifier)
                                    }
                                    print("Notification identifier: \(notification.identifier), Reminder identifier: \(oldReminder.identifier)")
                                }
                                print("Identifiers here 2: \(identifiers)")
                                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
                                
                                let trigger = self.notificationManager.addLocationEvent(forReminder: oldReminder, forEvent: EventType(rawValue: oldReminder.eventType!)!)
                                self.notificationManager.scheduleNewNotification(withReminder: oldReminder, locationTrigger: trigger)
                            }
                        }
                        
                        
                    }
                }
            }
            
        } else {
            // New reminder when using the compose cell way.
            let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: context!) as! Reminder
            reminder.text = text
            reminder.location = location
            if geoRegion?.identifier != nil {
                reminder.identifier = geoRegion?.identifier
            } else {
                reminder.identifier = identifier
            }
            
            // I would set these to NSNumber because I was not able to create NSManaged properties of type Double or Float.
            reminder.latitude = latitude as? NSNumber
            reminder.longitude = longitude as? NSNumber
            reminder.radius = radius as? NSNumber
            reminder.eventType = eventType?.rawValue
            context?.saveChanges() // Save those changes!
            if geoRegion != nil {
                geoRegionDelegateC?.monitorRegionB(geoRegion!)
                guard let eventType = eventType else { return }
                let trigger = notificationManager.addLocationEvent(forReminder: reminder, forEvent: eventType)
                notificationManager.scheduleNewNotification(withReminder: reminder, locationTrigger: trigger)
                
                notificationCenter.getPendingNotificationRequests { (notificationRequests) in
                    print("All notifications requests here: \(notificationRequests)\n")
                }
            }
            
        }

    }

    // Configure the view.
    func configureView() {
        locationSwitch.isOn = false
        if self.reminder != nil {
            if let oldReminder = self.reminder {
                textView.text = oldReminder.text
                if oldReminder.eventType != nil {
                    locationSwitch.isOn = true
                    self.latitude = oldReminder.latitude as? Double
                    self.longitude = oldReminder.longitude as? Double
                    self.eventType = EventType(rawValue: oldReminder.eventType!)
                    self.identifier = oldReminder.identifier
                    self.location = oldReminder.location
                    
                    if oldReminder.eventType == "On Entry" {
                        locationNameLabel.text = "Arriving: \(oldReminder.location!)" // I used the stored location string
                    } else {
                        locationNameLabel.text = "Leaving: \(oldReminder.location!)"
                    }
                    
                }
            }
            
        } else {
            textView.text = textViewText // The reminder text of course into the textview
        }
    }
    
    @IBAction func switchToggled(_ sender: UISwitch) {
        
        if sender.isOn {
        } else {
            // Check to see if geoRegion is nil, if not then make it nil because toggle is off.
            if geoRegion != nil {
                geoRegion = nil
            }
            // If reminder identifier is not nil then remove that notification from existence if there is an existing notification.
            if reminder?.identifier != nil {
                notificationCenter.getPendingNotificationRequests { (notificationRequests) in
                    var identifiers: [String] = []
                    for notification: UNNotificationRequest in notificationRequests {
                        if notification.identifier == self.reminder?.identifier! {
                            identifiers.append(notification.identifier)
                        }
                        print("Notification identifier: \(notification.identifier), Reminder identifier: \(self.reminder?.identifier)")
                    }
                    print("Identifiers here: \(identifiers)")
                    self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
                }
            }
        }
        
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // The location switch animation basically where the magic happens
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 && locationSwitch.isOn == false && indexPath.section == 1 {
            return 0.0
        }
        
        return 44.0

    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    // Send that data :)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocation" {
            let locationVC = segue.destination as! LocationController
            locationVC.geoSaveDelegate = self
            locationVC.geoIdentifier = self
            locationVC.geoRegionDelegate = self

            if let oldReminder = reminder {
                if oldReminder.eventType != nil && reminder != nil {
                    locationVC.eventType = EventType(rawValue: oldReminder.eventType!)
                    locationVC.identifier = oldReminder.identifier
                    locationVC.longitude = oldReminder.longitude as? Double
                    locationVC.latitude = oldReminder.latitude as? Double
                    locationVC.radius = oldReminder.radius as? Double
                    locationVC.reminder = oldReminder
                    
                }
            }
        }
    }
}

extension ReminderDetailController: LocationPermissionsDelegate, LocationManagerDelegate {
    // Delegate methods
    
    func authorizationSucceeded() {
        print("Authorized")
    }
    
    func authorizationFailedWithStatus(_ status: CLAuthorizationStatus) {
        print(status)
    }
    
    func obtainedCoordinates(_ coordinate: Coordinate) {
        print(coordinate)
    }
    
    func failedWithError(_ error: LocationError) {
        print(error)
    }
    
    
}

























