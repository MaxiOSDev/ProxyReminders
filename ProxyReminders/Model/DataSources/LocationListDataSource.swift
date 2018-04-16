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

// SO much happening here.
class LocationListDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    
    private let tableView: UITableView
    private let searchController: UISearchController
    var mapView: MKMapView? = nil
    
    // Now this is the selected pin, and necessary stored propeties for my map view to work with the pin and location selected.
    var selectedPin: MKPlacemark? = nil
    var userLocationPlacemark: CLPlacemark?
    var handleMapSearchDelegate: HandleMapSearch? = nil
    var matchingItems: [MKMapItem] = []
    var location: String?
    var inSearchMode: Bool? = false
    var delegate: MapViewDelegate?
    var container: UIView?
    var circleRenderer: MKCircleRenderer! // The circle renderer
    weak var monitorRegion: GeoRegionDelegate?
    weak var geoIdentifier: GeoIdentifierA? // The identifier
    weak var geoSaveB: GeoSaveB? // Saving a bunch of propeties that is sent to LocationVC.
    var oldLatitude: Double?
    var oldLongitude: Double?
    
    var reminder: Reminder?
    var segmentedControl: UISegmentedControl!
    
    init(tableView: UITableView, searchController: UISearchController, mapView: MKMapView, container: UIView?, control: UISegmentedControl?) {
        self.tableView = tableView
        self.searchController = searchController
        self.mapView = mapView
        self.container = container
        self.segmentedControl = control
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
    
    // Got it from stack overflow, very, and I mean very helpful for the address label
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
            let item = matchingItems[indexPath.row].placemark // This crashes if you type too fast in the search bar. So type..Slow.
            // Could fix it by using SHSearhBar (way better seach bar library I used for project 10) and not the search bar given to us by Apple
            cell.locationNameLabel.text = item.name
            cell.locationAddressLabel.text = parseAddress(selectedItem: item)
            return cell
        } else {
            if reminder?.eventType != nil {
                
                // Magic of getting that location
                let geoCoder = CLGeocoder()
                let latitude: CLLocationDegrees = reminder?.latitude as! Double
                let longitude: CLLocationDegrees = reminder?.longitude as! Double
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    var placemark: CLPlacemark!
                    placemark = placemarks?[0]
                    
                    if let locationName = placemark.name {
                        print(locationName)
                    }
                    
                    let mkplacemark = MKPlacemark(placemark: placemark)
                    cell.locationNameLabel.text = self.reminder?.location
                    cell.locationAddressLabel.text = self.parseAddress(selectedItem: mkplacemark)
                    self.delegate?.showMap(for: self.mapView!)
                    self.dropPinZoomIn(placemark: mkplacemark)
                    // I used to start monitoring as soon as I would drop that pin. But I decided to start monitoring when the reminder is saved with a location.
                 //   let coordinate = Coordinate(location: mkplacemark.location!)
                 //   self.monitorDelegate?.startMonitoringCoordinates(coordinate)
                    
                }

            }
        }
        
        return cell
    }
}

extension LocationListDataSource: HandleMapSearch, MKMapViewDelegate, UISearchResultsUpdating, UISearchControllerDelegate {
    // Update search bar results in table view with whatever I type in the search bar
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
    
    // Drop that pin in the mapview
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
      //  let span = MKCoordinateSpanMake(0.05, 0.05)
        let span = MKCoordinateSpanMake(0.003, 0.003)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        
        // My region identifier is this! Also will end up being my reminder identifier
        let identifier = UUID().uuidString
        geoIdentifier?.saveIdentifier(identifier: identifier)
        let circleRegionCoordinate = CLLocationCoordinate2D(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
        let circleRegion = CLCircularRegion(center: circleRegionCoordinate, radius: 50.00, identifier: identifier)
       
        monitorRegion?.monitorRegion(circleRegion)
        // I am sending the region
        self.mapView?.removeOverlays(mapView.overlays)
        let circle = MKCircle(center: circleRegionCoordinate, radius: circleRegion.radius)
        self.mapView?.add(circle) // The geofence
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let container = container {
            delegate?.showMap(for: container) // Show the map when selecting a location
        }

        if matchingItems.count > 0 {
            let item = matchingItems[indexPath.row].placemark
     //       monitorDelegate?.startMonitoringCoordinates(coordinate) // I used to start monitoring when selecting a location, but not anymore.
            handleMapSearchDelegate?.dropPinZoomIn(placemark: item)
            geoSaveB?.dataSaved(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude, radius: 50.00, location: location) // Send data back to detail VC.
            searchController.isActive = false
        } else {
            if reminder?.eventType != nil {
                let geoCoder = CLGeocoder()
                let latitude: CLLocationDegrees = reminder?.latitude as! Double
                let longitude: CLLocationDegrees = reminder?.longitude as! Double
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    var placemark: CLPlacemark!
                    placemark = placemarks?[0]
                    
                    let mkplacemark = MKPlacemark(placemark: placemark)
                    // used to be start monitoring here as well.
                    // Send data back to detail vc.
                    self.geoSaveB?.dataSaved(latitude: mkplacemark.coordinate.latitude, longitude: mkplacemark.coordinate.longitude, radius: 50.00, location: self.location)
                }
                
            }
        }
        
        tableView.reloadData()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else {
            return MKOverlayRenderer()
        }
        
        circleRenderer = MKCircleRenderer(circle: circleOverlay)
        
        if segmentedControl.selectedSegmentIndex == 0 {
            circleRenderer.strokeColor = .blue
            circleRenderer.lineWidth = 1.5
            print("Line Width currently \(circleRenderer.lineWidth)")
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.4)
            
        }
        
        return circleRenderer
    }
    
}

extension LocationListDataSource: LocationPermissionsDelegate, LocationManagerDelegate, SavedReminderLocation {
    func savedLocation(for reminder: Reminder?) {
        self.reminder = reminder // assigning the reminder in here from location vc.
    }
    
    // Location Manager Delegates I built on top of what Pasan taught.
    
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





























































