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

protocol ReminderCellDelegate: AnyObject {
    func buttonCloseTapped(cell: ReminderCell)
}

protocol SegueDelegate {
    func callSegueFromCell(myData dataObject: AnyObject)
}

class ReminderListDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    let tableView: UITableView
    let context: NSManagedObjectContext
    var indexPathForSelectedRow: IndexPath?
    var delegate: SegueDelegate?
    
    lazy var fetchedResultsController: ReminderFetchedResultsController = {
       return ReminderFetchedResultsController(managedObjectContext: context, tableView: tableView)
    }()
    
    init(tableView: UITableView, context: NSManagedObjectContext) {
        self.tableView = tableView
        self.context = context
    }
    
    func reminderSelectedRow() -> IndexPath {
        print("Inside body of reminderSelectedRow function \(indexPathForSelectedRow)")
        return indexPathForSelectedRow!
    }
    
    func object(at indexPath: IndexPath) -> Reminder {
        return fetchedResultsController.object(at: indexPath)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count + 1
        }
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) && (fetchedResultsController.fetchedObjects?.isEmpty)! {
            return 0
        } else if (section == 1) {
            return 1
        } else if (section == 0) && !(fetchedResultsController.fetchedObjects!.isEmpty) {
            guard let sections = fetchedResultsController.sections else { fatalError("No sections in fectched results controller") }
            let sectionInfo = sections[0]
            return sectionInfo.numberOfObjects // Here could be fetchedResultsController.fetchedObjects.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let reminderCell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell", for: indexPath) as! ReminderCell
            reminderCell.backgroundColor = .clear
            reminderCell.selectionStyle = .none
            return configureCell(reminderCell, at: indexPath)
        } else {
            let composeCell = tableView.dequeueReusableCell(withIdentifier: "ComposeCell", for: indexPath) as! ComposeCell
            composeCell.backgroundColor = .clear
            composeCell.selectionStyle = .none
            return composeCell
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let reminder = fetchedResultsController.object(at: indexPath)
        self.context.delete(reminder)
        self.context.saveChanges()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func composeCellHelper() {
        
        let indexPath = IndexPath(row: 0, section: 1)
        print("IndexPath here \(indexPath)")
        
        let cell = tableView.cellForRow(at: indexPath) as! ComposeCell
        
        print("Cell? \(cell)")
        guard let text = cell.textView.text, !cell.textView.text.isEmpty else { return }
        let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: context) as! Reminder
        reminder.text = text
        context.saveChanges()
    }
    
    func configureCell(_ cell: ReminderCell, at indexPath: IndexPath) -> UITableViewCell {
        if let objects = fetchedResultsController.fetchedObjects {
            let reminder = objects[indexPath.row]
            cell.textView.text = reminder.text
            indexPathForSelectedRow = indexPath
            cell.delegate = self
            return cell
        }
        
        return cell
    }

}

extension ReminderListDataSource: ReminderCellDelegate {
    func buttonCloseTapped(cell: ReminderCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        indexPathForSelectedRow = indexPath
        //    print("Inside datasource \(indexPathForSelectedRow)")
        delegate?.callSegueFromCell(myData: self)
    }
}
















