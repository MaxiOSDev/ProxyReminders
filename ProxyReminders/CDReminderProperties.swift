//
//  CDReminderProperties.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import Foundation
import CoreData

public class Reminder: NSManagedObject {}

extension Reminder {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        let request = NSFetchRequest<Reminder>(entityName: "Reminder")
        request.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true)]
        return request
    }
    
    @NSManaged public var text: String
    @NSManaged public var identifier: String?
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var radius: NSNumber?
    @NSManaged public var eventType: String?
    @NSManaged public var location: String?
    
}
