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
        // As learnt in a blog

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
        
        dataSource.delegate = self
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // The adding of a reminder with the bar button item
    @IBAction func addReminder(_ sender: UIBarButtonItem) {
//        let indexPath = IndexPath(row: 0, section: 0)
//        let cell = tableView.cellForRow(at: indexPath) as! ReminderCell
//
//        guard let text = cell.textView.text, !cell.textView.text.isEmpty else { return }
//        let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: context) as! Reminder
//        reminder.text = text
//        context.saveChanges()
//        tableView.reloadData()
        performSegue(withIdentifier: "composeDetail", sender: self)
    }
    
    // Compose of a reminder with the add button inside the compose cell
    @IBAction func composeReminder(_ sender: Any) {
        let indexPath = IndexPath(row: 0, section: 1)
        let cell = tableView.cellForRow(at: indexPath) as! ComposeCell
        
        guard let text = cell.textView.text, !cell.textView.text.isEmpty else { return }
        let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: context) as! Reminder
        reminder.text = text
        context.saveChanges()
        tableView.reloadData()
    }
    
    // Send data to next view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

            if let navController = segue.destination as? UINavigationController {
                let detailPage = navController.topViewController as! ReminderDetailController
                if segue.identifier == "showDetail" {
                    let indexPath = dataSource.reminderSelectedRow()
                    detailPage.context = self.context
                    let reminder = self.dataSource.object(at: indexPath)
                    detailPage.reminder = reminder
                    
                } else if segue.identifier == "composeDetail" {
                    let indexPath = IndexPath(row: 0, section: 1)
                    let cell = tableView.cellForRow(at: indexPath) as! ComposeCell
                    detailPage.context = self.context
                    detailPage.textViewText = cell.textView.text
            
                }
            }
    }
}

// Since I started over, I ran into lots of issues even as simple as using a segue, so got this from S.O.
extension RemindersListController: SegueDelegate {
    func callSegueFromCell(myData dataObject: AnyObject) {
        self.performSegue(withIdentifier: "showDetail", sender: dataObject)
    }
}












