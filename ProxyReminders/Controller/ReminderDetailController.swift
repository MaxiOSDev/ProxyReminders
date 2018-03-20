//
//  ReminderDetailController.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import CoreData

enum EventType: String {
    case onEntry = "On Entry"
    case onExit = "On Exit"
}

class ReminderDetailController: UITableViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var context: NSManagedObjectContext?
    var reminder: Reminder?
    var latitude: Double?
    var longitude: Double?
    var eventType: EventType?
    var identifier: String?
    var radius: Double?
    var location: String?
    var textViewText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0 , 0)
        tableView.tableFooterView = UIView(frame: .zero)
        print("Reminder \(reminder)")
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveReminder(_ sender: Any) {
        guard let text = textView.text, !textView.text.isEmpty else { return }
        
        if self.reminder != nil {
            if let oldReminder = self.reminder {
                oldReminder.text = text
                oldReminder.latitude = latitude as NSNumber?
                oldReminder.longitude = longitude as NSNumber?
                oldReminder.radius = radius as NSNumber?
                oldReminder.identifier = identifier
                oldReminder.eventType = eventType?.rawValue
                oldReminder.location = location
                context?.saveChanges()
            }
        } else {
            let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: context!) as! Reminder
            reminder.text = text
            context?.saveChanges()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
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
                        locationNameLabel.text = "Arriving: \(oldReminder.location!)"
                    } else {
                        locationNameLabel.text = "Leaving: \(oldReminder.location!)"
                    }
                    
                }
            }
        } else {
            textView.text = textViewText
        }
    }
    
    @IBAction func switchToggled(_ sender: UISwitch) {
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 && locationSwitch.isOn == false && indexPath.section == 1 {
            return 0.0
        }
        
        return 44.0

    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLocation" {
            
        }
    }



}
