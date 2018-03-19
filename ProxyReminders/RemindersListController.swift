//
//  RemindersListController.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import CoreData

class RemindersListController: UITableViewController {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var context = CoreDataStack().managedObjectContext
    
    lazy var fetchedResultsController: ReminderFetchedResultsController = {
       return ReminderFetchedResultsController(managedObjectContext: self.context, tableView: tableView)
    }()
    
    lazy var dataSource: ReminderListDataSource = {
        return ReminderListDataSource(tableView: tableView, context: self.context)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        dataSource.delegate = self
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func addReminder(_ sender: UIBarButtonItem) {
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! ReminderCell
        
        guard let text = cell.textView.text, !cell.textView.text.isEmpty else { return }
        let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: context) as! Reminder
        reminder.text = text
        context.saveChanges()
        tableView.reloadData()
    }
    
    @IBAction func composeReminder(_ sender: Any) {
        let indexPath = IndexPath(row: 0, section: 1)
        let cell = tableView.cellForRow(at: indexPath) as! ComposeCell
        
        guard let text = cell.textView.text, !cell.textView.text.isEmpty else { return }
        let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: context) as! Reminder
        reminder.text = text
        context.saveChanges()
        tableView.reloadData()
    }
    
    
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

extension RemindersListController: SegueDelegate {
    func callSegueFromCell(myData dataObject: AnyObject) {
        self.performSegue(withIdentifier: "showDetail", sender: dataObject)
    }
    
    
}












