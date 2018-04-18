//
//  RemindersListController.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CoreLocation

// My Master View Controller
class RemindersListController: UITableViewController {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var context = CoreDataStack().managedObjectContext
    
    // Lazily loaded FetchedResultsController
    lazy var fetchedResultsController: ReminderFetchedResultsController = {
       return ReminderFetchedResultsController(managedObjectContext: self.context, tableView: tableView)
    }()
    
    // Lazily loaded datasource
    lazy var dataSource: ReminderListDataSource = {
        return ReminderListDataSource(tableView: tableView, context: self.context)
    }()
 
    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.applicationIconBadgeNumber = 0 // Sets badge number back to 0
        let manager = CLLocationManager()
        print(manager.monitoredRegions.count)
        
        for identifier in manager.monitoredRegions {
            print(identifier.identifier)
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            print(notificationRequests.count)
        }
        
        // Setting the datasource and delegate
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        
       // dataSource.delegate = self
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segueAction(_ sender: UIButton) {
        if dataSource.indexPathForSelectedRow != nil {
            performSegue(withIdentifier: "showDetail", sender: self)
        }
    }
    
    // Send data to next view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

            if let navController = segue.destination as? UINavigationController {
                
                if segue.identifier == "showDetail" {
                    guard let detailPage = navController.topViewController as? ReminderDetailController else { return }
                    detailPage.context = self.context
                    let indexPath = dataSource.reminderSelectedRow()
                    let reminder = self.dataSource.object(at: indexPath)
                    detailPage.reminder = reminder
                } else if segue.identifier == "newReminder" {
                    guard let detailPage = navController.topViewController as? ReminderDetailController else { return }
                    detailPage.context = self.context
                }
        }
    }
}













