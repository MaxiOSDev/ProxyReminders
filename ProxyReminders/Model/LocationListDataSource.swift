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

protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

class LocationListDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    private let tableView: UITableView
    private let searchController: UISearchController
    var locationManager = CLLocationManager()
    var mapView: MKMapView?
    var selectedPin: MKPlacemark? = nil
    var userLocationPlacemark: CLPlacemark?
    var handleMapSearchDelegate: HandleMapSearch? = nil
    var matchingItems: [MKMapItem] = []
    var location: String?
    var inSearchMode: Bool? = false
    var delegate: MapViewDelegate?
    var container: UIView?
    
    init(tableView: UITableView, searchController: UISearchController, mapView: MKMapView, container: UIView?) {
        self.tableView = tableView
        self.searchController = searchController
        self.mapView = mapView
        self.container = container
        super.init()
        handleMapSearchDelegate = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if inSearchMode! {
            return matchingItems.count
        }
        
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath) as! LocationCell
        
        return configureCell(cell, at: indexPath)
    }
    
    func parseAddress(selectedItem: MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
    
    func configureCell(_ cell: LocationCell, at indexPath: IndexPath) -> UITableViewCell {
        
        if matchingItems.count > 0 {
            let item = matchingItems[indexPath.row].placemark
            cell.locationNameLabel.text = item.name
            cell.locationAddressLabel.text = parseAddress(selectedItem: item)
            return cell
        }
        
        return cell
    }
}

extension LocationListDataSource: HandleMapSearch, MKMapViewDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView else { return }
        guard let searchBarText = searchController.searchBar.text else { return }
        if searchBarText != "" {
            inSearchMode = true
        } else {
            inSearchMode = false
        }
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start() { response, _ in
            guard let response = response else { return }
            self.matchingItems = response.mapItems
            self.delegate?.hideMap()
            print(self.matchingItems.count)
            self.tableView.reloadData()
        }
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
    
    func dropPinZoomIn(placemark: MKPlacemark) {
        selectedPin = placemark
        
        guard let mapView = mapView else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        self.location = placemark.name
        
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let container = container {
            delegate?.showMap(for: container)
        }

        
        if matchingItems.count > 0 {
            let item = matchingItems[indexPath.row].placemark

            handleMapSearchDelegate?.dropPinZoomIn(placemark: item)
            searchController.isActive = false
        }
        
        tableView.reloadData()
    }
    
}

extension LocationListDataSource: LocationPermissionsDelegate, LocationManagerDelegate {
    func authorizationSucceeded() {
        print("Authorization Succeeded")
    }
    
    func authorizationFailedWithStatus(_ status: CLAuthorizationStatus) {
        print(status)
    }
    
    func obtainedCoordinates(_ coordinate: Coordinate) {
        let geoCoder = CLGeocoder()
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            var placemark: CLPlacemark!
            placemark = placemarks?[0]
            self.userLocationPlacemark = placemark
        }
    }
    
    func failedWithError(_ error: LocationError) {
        print(error)
    }
    
}





























































