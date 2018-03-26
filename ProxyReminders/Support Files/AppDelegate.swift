//
//  AppDelegate.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let manager = CLLocationManager()
    let context = CoreDataStack().managedObjectContext
    var regions = [CLRegion]()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        
        return true
    }
    
    func handleEvent(forRegion region: CLRegion, reminder: Reminder) {
        func handleEvent(forRegion region: CLRegion, reminder: Reminder) {
            
            let content = UNMutableNotificationContent()
            
            let text = reminder.text
            guard let identifier = reminder.identifier else { return }
            
            content.title = text
            print("The text is here. It worked within App Delegate! \(text)")
            content.sound = .default()
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            let center = UNUserNotificationCenter.current()
            center.add(request) { (erorr) in
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            print("Notification Requests count when entering the background the app: \(notificationRequests)")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            print("Notification Requests count when terminating the app: \(notificationRequests)")
        }
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "ProxyReminders")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Did enter region: \(region.identifier)")
        regions.append(region)
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        do {
            let reminders = try context.fetch(fetchRequest)
            for proxyReminder in reminders {
                for geoRegion in regions {
                    print("Geo Region Identifiers: \(geoRegion.identifier)")
                    print("Proxy Reminder: \(proxyReminder.text) \(proxyReminder.identifier)")
                    if let proxyIdentifier = proxyReminder.identifier {
                        if proxyIdentifier == region.identifier {
                            handleEvent(forRegion: region, reminder: proxyReminder)
                        } else {
                            print("Not these: \(proxyIdentifier) & \(region.identifier)")
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Did exit region: \(region.identifier)")
        
        regions.append(region)
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        do {
            let reminders = try context.fetch(fetchRequest)
            for proxyReminder in reminders {
                for geoRegion in regions {
                    print("Geo Region Identifiers: \(geoRegion.identifier)")
                    print("Proxy Reminder: \(proxyReminder.text) \(proxyReminder.identifier)")
                    if let proxyIdentifier = proxyReminder.identifier {
                        if proxyIdentifier == region.identifier {
                            handleEvent(forRegion: region, reminder: proxyReminder)
                        } else {
                            print("Not these: \(proxyIdentifier) & \(region.identifier)")
                        }
                    }
                }
            }
        } catch {
            print(error)
        }

    }
}






