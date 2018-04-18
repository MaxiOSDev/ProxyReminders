//
//  ReminderListDataSource.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreLocation
import UserNotifications

// My data source for reminders.
class ReminderListDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let tableView: UITableView
    let context: NSManagedObjectContext
    let locationManager = CLLocationManager()
    var indexPathForSelectedRow: IndexPath?
    var notificationCenter = UNUserNotificationCenter.current()
    
    // Lazily loaded FRC
    lazy var fetchedResultsController: ReminderFetchedResultsController = {
       return ReminderFetchedResultsController(managedObjectContext: context, tableView: tableView)
    }()
    
    init(tableView: UITableView, context: NSManagedObjectContext) {
        self.tableView = tableView
        self.context = context
    }
    
    // Getting object from fetchedResults controller at selected indexPath
    func object(at indexPath: IndexPath) -> Reminder {
        return fetchedResultsController.object(at: indexPath)
    }
    
    func reminderSelectedRow() -> IndexPath {
        return indexPathForSelectedRow!
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    // The difficult part honestly. To make sure the proper rows were in section 0 or 1
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController.sections?[section] else { return 0 }
        
        return section.numberOfObjects
    }
    
    // The reminder cell are the already saved reminders, the compose cell is like in the Reminders App, a reminder that is being created but not saved yet.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let reminderCell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) as! ReminderCell
            reminderCell.backgroundColor = .clear
            reminderCell.selectionStyle = .none
            return configureCell(reminderCell, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let reminder = fetchedResultsController.object(at: indexPath)
        
        if let identifier = reminder.identifier {
            
            notificationCenter.getPendingNotificationRequests { (notificationRequests) in
                var identifiers: [String] = []
                for notification: UNNotificationRequest in notificationRequests {
                    if notification.identifier == identifier {
                        identifiers.append(notification.identifier)
                    }
                    print("Notification identifer: \(notification.identifier), reminder identifier: \(identifier)")
                }
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            self.context.delete(reminder)
            self.context.saveChanges()
        } else {
            self.context.delete(reminder)
            self.context.saveChanges()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    // Make sure that reminder cell gets populated with reminders.
    func configureCell(_ cell: ReminderCell, at indexPath: IndexPath) -> UITableViewCell {
        if let objects = fetchedResultsController.fetchedObjects {
            let reminder = objects[indexPath.row]
            cell.textView.text = reminder.text
            cell.delegate = self
            return cell
        }
        
        return cell
    }
}

extension ReminderListDataSource: ReminderCellDelegate {
    // This was needed for the proper indexpath to be selected
    func buttonCloseTapped(cell: ReminderCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        indexPathForSelectedRow = indexPath
    }
    
    func stopMonitoringLocation(for reminder: Reminder) {
        for monitoredRegion in locationManager.monitoredRegions {
            if monitoredRegion.identifier == reminder.identifier {
                locationManager.stopMonitoring(for: monitoredRegion)
            }
        }
    }
}
















