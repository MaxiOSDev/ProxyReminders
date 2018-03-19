//
//  LocationListDataSource.swift
//  ProxyReminders
//
//  Created by Max Ramirez on 3/19/18.
//  Copyright © 2018 Max Ramirez. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class LocationListDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView
    private let searchController: UISearchController
    
    init(tableView: UITableView, searchController: UISearchController) {
        self.tableView = tableView
        self.searchController = searchController
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath) as! LocationCell
        
        return cell
    }
}






























































