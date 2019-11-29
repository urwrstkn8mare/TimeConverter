//
//  ViewController.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 3/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

// Name: Time Converter
// Purpose: To create an MVP for Computer Science assessemnt.
// Description: This iOS application is an intuitive way to convert time between
//              time zones.
// Date of last revision: 28/11/2019 (you should just check git though)

// Notes:
//  - Ignore any Log() functions they are just for my own debugging use.

// The above covered:
//  - ViewController.swift
//  - TimesPanelViewController.swift
//  - SearchPanelViewController.swift
//  - BackendAndOther.swift

import CoreLocation
import FloatingPanel // https://github.com/SCENEE/FloatingPanel
import Foundation
import MapKit
import SwiftLocation // https://github.com/malcommac/SwiftLocation
import SwiftyPickerPopover // https://github.com/urwrstkn8mare/SwiftyPickerPopover
import UIKit

// MARK: ViewController

class ViewController: UIViewController {
    // Outlets (from storyboard).
    @IBOutlet var sideButtons: UIVisualEffectView!
    @IBOutlet var searchIconView: UIView!
    @IBOutlet var locationIconView: UIView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var searchIconImageView: UIImageView!
    @IBOutlet var locationIconImageView: UIImageView!

    // Class properties for use all around the class (you'll find out more
    // about them later).
    var fpc: FloatingPanelController!
    var fpcSearch: FloatingPanelController!
    var fpcSearchShownBefore: Bool = false
    var locationButtonPressedBefore: Bool = false
    var locationManager: CLLocationManager!
    var contentVC: TimesPanelViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13, *) {
            // If the app is on iOS 13 or later than use SFSymbols provided by apple.
            searchIconImageView.image = UIImage(systemName: "magnifyingglass")
            locationIconImageView.image = UIImage(systemName: "location")
        } else {
            // If the app is on anything earlier than iOS 13 than use bitmaps (png)
            // of the apple SFSymbols.
            searchIconImageView.image = UIImage(named: "magnifyingglass-image")
            locationIconImageView.image = UIImage(named: "location-image")
        }

        // To prevent showing user location by default on the map.
        mapView.showsUserLocation = false

        // Setting the delegate of the mapview to this class (self).
        mapView.delegate = self

        // Programatically setting up a long press gesture recogniser and its
        // target.
        let longPressGestureRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(mapViewLongPress(recogniser:)))
        // Setting the minimum duration the user must hold down on the map to
        // trigger the recogniser.
        longPressGestureRecogniser.minimumPressDuration = 0.35
        // Adding the recogniser to the mapview.
        mapView.addGestureRecognizer(longPressGestureRecogniser)

        // Setting up the side buttons on the map.
        sideButtons.layer.cornerRadius = 10.0
        sideButtons.clipsToBounds = true
        sideButtons.layer.borderWidth = 1
        if #available(iOS 13, *) {
            // If the device is running iOS 13 or later than use system
            // "opaqueSeparator" colour.
            sideButtons.layer.borderColor = UIColor.opaqueSeparator.cgColor
        } else {
            // If the device is running an OS earlier than iOS 13 than use
            // practically the same colour but just from raw RGB values.
            sideButtons.layer.borderColor = UIColor(red: 198.0 / 255.0, green: 198.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0).cgColor
        }

        // Initially settings up the position of the sidebuttons on the y-axis.
        sideButtons.frame = CGRect(x: sideButtons.frame.minX, y: (UIScreen.main.bounds.height / 2) - 20 - sideButtons.frame.height, width: sideButtons.frame.width, height: sideButtons.frame.height)

        // Initialize a `FloatingPanelController` object.
        fpc = FloatingPanelController()

        // Assign this class (self) as the delegate of the controller.
        fpc.delegate = self

        // Setting the background colour of the FloatingPanel to clear.
        fpc.surfaceView.backgroundColor = .clear

        // If iOS version is 11 or later than set round corners. If not
        // we will do it manually later.
        if #available(iOS 11, *) {
            fpc.surfaceView.cornerRadius = 9.0
        } else {
            fpc.surfaceView.cornerRadius = 0.0
        }

        // Add a shadow.
        fpc.surfaceView.shadowHidden = false

        // Initialising the content view controller of the floating panel
        // controller to the Times Panel View Controller from the storyboard.
        if #available(iOS 13.0, *) {
            contentVC = (storyboard?.instantiateViewController(identifier: "TimesPanel") as? TimesPanelViewController)!
        } else {
            contentVC = (storyboard?.instantiateViewController(withIdentifier: "TimesPanel") as? TimesPanelViewController)!
        }

        // Setting some custom delegates for the content view controller
        // to facilliate communication between this controller and the content
        // view controller.
        contentVC?.removeAnnotationDelegate = self
        contentVC?.setMapCentreDelegate = self

        // Setting the content view controller of the floating panel controller
        // to the contentVC just initialised.
        fpc.set(contentViewController: contentVC)
        // Allowing the floating panel controller to track the table view scroll.
        fpc.track(scrollView: contentVC?.tableView)

        // Adding the views managed by the floating panel controller to the
        // view.
        fpc.addPanel(toParent: self)

        // Setting up a search modal (also via floating panel) similarly to the
        // main floating panel.
        fpcSearch = FloatingPanelController()
        fpcSearch.delegate = self
        fpcSearch.surfaceView.backgroundColor = .clear

        // Hiding the grabber handle of the search floating panel.
        fpcSearch.surfaceView.grabberHandle.isHidden = true

        // This stuff doesn't really work but I'm leaving it in.
        fpcSearch.panGestureRecognizer.isEnabled = false
        fpcSearch.isRemovalInteractionEnabled = true

        // Initialising the content view controller of the search modal (search
        // floating panel).
        var searchContentVC: SearchPanelViewController
        if #available(iOS 13.0, *) {
            searchContentVC = (storyboard?.instantiateViewController(identifier: "searchPanel") as? SearchPanelViewController)!
        } else {
            // Fallback on earlier versions
            searchContentVC = (storyboard?.instantiateViewController(withIdentifier: "searchPanel") as? SearchPanelViewController)!
        }

        // Passing the main floating panel controller to the search modal content
        // view controller.
        searchContentVC.fpc = fpcSearch

        // Another custom delegate to faciliate communication.
        searchContentVC.cellTapDelegate = self

        // Setting the content view controller to the initialised content view
        // controller.
        fpcSearch.set(contentViewController: searchContentVC)

        // Find out about this method at the method definition.
        loadAnnotations()
    }

    // This method runs whenever the device changes orientation (rotates).
    override func viewWillTransition(to _: CGSize, with _: UIViewControllerTransitionCoordinator) {
        let isLandscape = UIDevice.current.orientation.isLandscape
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad ? true : false
        let bounds = UIScreen.main.bounds

        // The heights of iPads and iPhones for some reason are different (as in on
        // which side). This meant I have to account for that as well.
        var height: CGFloat?
        if isIpad {
            height = bounds.height
        } else {
            height = bounds.width
        }

        if isLandscape {
            // If the device is in landscape use this y coordinate.
            sideButtons.frame = CGRect(x: sideButtons.frame.minX, y: (height! / 2) - (sideButtons.frame.height / 2), width: sideButtons.frame.width, height: sideButtons.frame.height)
        } else {
            // If the device is in portrait use this y coordinate.
            sideButtons.frame = CGRect(x: sideButtons.frame.minX, y: (height! / 2) - 20 - sideButtons.frame.height, width: sideButtons.frame.width, height: sideButtons.frame.height)
        }

        // The FloatingPanel pod has a problem right now where sometimes the
        // update layout method of the controller that changes the layout (learn
        // about that in the layouts in the TimesPanelController.swift) is not
        // called when the orientation of the device is changed. Thus I have to
        // manually call it.
        fpc.updateLayout()
    }
    
    @objc func mapViewLongPress(recogniser: UIGestureRecognizer) {
        if recogniser.state == UIGestureRecognizer.State.began {
            // Converts the point on the screen on which the user held down
            // to coordinates for a map.
            let touchPoint = recogniser.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // Gets the new id of the new annotation.
            let newId = addAnnotation(item: MKMapItem(placemark: MKPlacemark(coordinate: newCoordinates)))
            if newId != nil {
                // Reverse geocoding after to not have any visual lag.
                LocationManager.shared.locateFromCoordinates(newCoordinates, service: .apple(GeocoderRequest.Options())) { result in
                    switch result {
                    case let .failure(error):
                        Log("Geoocoder Error: \(error)")
                        
                        // Tell the user the geocoding failed most likely because
                        // they have no internet. The app does not require
                        // internet to convert time but it does to search
                        // and create new locations.
                        let alert = UIAlertController(title: "Geocoding failed", message: "Failed to get data on this location, try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { action in
                            self.removeAnnotation(id: newId!)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    case let .success(places):
                        // I passed in the coordinates and it returns a list of
                        // Place objects. I just get the placemark of the
                        // first object.
                        if let placemark = places.first?.placemark {
                            // I turn that into a MKMapItem for core data.
                            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                            // I use my class for interfacing with cordedata to
                            // update the data with this new information.
                            LocationStore().update(id: newId!, newLocation: mapItem, newId: nil)
                            self.contentVC?.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    func loadAnnotations() {
        // This method removes all previous annotations for a blank slate, then
        // creates annotations based on locations stored in coredata.
        let locationStore = LocationStore()
        mapView.removeAnnotations(mapView.annotations)
        for locationStruct in locationStore.read() {
            let newAnnotation = CustomAnnotationClass(id: locationStruct.id, coordinate: locationStruct.location.placemark.coordinate)
            mapView.addAnnotation(newAnnotation)
        }
    }

    func addAnnotation(item: MKMapItem) -> Int? {
        let locationStore = LocationStore()

        // this variable just defines the maximum number of annotations allowed.
        let maxCount: Int
        if #available(iOS 13, *) {
            maxCount = 50
        } else {
            maxCount = 10
        }

        let result = locationStore.read()
        if result.count == maxCount {
            // This alert is given to the user if the number of locations in
            // coredata reaches the maximum limit for annotations for the iOS
            // version.
            let alert = UIAlertController(title: "Too many locations!", message: "You can only create a maximum of \(maxCount) locations.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: true)
            return nil
        } else {
            let distanceApartOtherAnnotationsMustBe: Int = 900_000

            // Creates a new location in core data and then stores the new id
            // assigned to it in a variable.
            let newId = locationStore.create(locationParam: item)

            // Creates a new annotation based on the custom annotation created by
            // me.
            let newAnnotation = CustomAnnotationClass(id: newId!, coordinate: item.placemark.coordinate)

            // Adds that annotation to the map.
            mapView.addAnnotation(newAnnotation)

            for locationStruct in result {
                // For every location (item) in core data, check if the distance from
                // the new location is the same distance from that location. If it
                // is then...
                if (item.placemark.location?.distance(from: locationStruct.location.placemark.location!))! < Double(distanceApartOtherAnnotationsMustBe + 1) {
                    Log("too close")

                    // Move the map to be centered on the location that was too
                    // close to the new location.
                    setMapCentre(coordinate: locationStruct.location.placemark.coordinate)
                    
                    // Remove the annotation from the map and delete it from core
                    // data
                    mapView.removeAnnotation(newAnnotation)
                    locationStore.delete(id: newId!)

                    // Give the user an alert explaining what happened.
                    let alert = UIAlertController(title: "Too many close!", message: "Your location must be at least \(distanceApartOtherAnnotationsMustBe / 1000)km away from any other location.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    present(alert, animated: true)

                    return nil
                }
            }

            return newId
        }
    }

    @IBAction func handleSearchTap(recogniser _: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.1, animations: {
            () in
            if #available(iOS 13, *) {
                // If the device is running iOS 13 or later than use the system
                // opaque seperator colour.
                self.searchIconView.backgroundColor = UIColor.opaqueSeparator
            } else {
                // If the device is running iOS 12 or earlier, than use the same
                // colour but via a RGB value.
                self.searchIconView.backgroundColor = UIColor(red: 198.0 / 255.0, green: 198.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0)
            }
            // Set the opacity of the view to 80%.
            self.searchIconView.alpha = 0.8
        }, completion: {
            (_: Bool) in
            // Ounce the animation is done, finish with returning the view's colour
            // to clear and the opacity to 100%.
            self.searchIconView.backgroundColor = .clear
            self.searchIconView.alpha = 1
        })

        // Present the search floating panel (modal).
        present(fpcSearch, animated: true, completion: nil)
    }

    @IBAction func handleLocationTap(recogniser _: UITapGestureRecognizer) {
        // Same animation as the one used in handleSearchTap(). Just with a
        // different view.
        UIView.animate(withDuration: 0.1, animations: { () in
            if #available(iOS 13, *) {
                self.locationIconView.backgroundColor = UIColor.opaqueSeparator
            } else {
                self.locationIconView.backgroundColor = UIColor(red: 198.0 / 255.0, green: 198.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0)
            }
            self.locationIconView.alpha = 0.8
        }, completion: { (_: Bool) in
            self.locationIconView.backgroundColor = .clear
            self.locationIconView.alpha = 1
        })

        // Set the location manager to require user authorization only when the
        // location is requested.
        LocationManager.shared.requireUserAuthorization(.whenInUse)
        
        // Toggle whether the map shows the user location or not.
        mapView.showsUserLocation = !mapView.showsUserLocation

        if mapView.showsUserLocation {
            // If the map view is set to show the device's location, than get the
            // location only ounce (not continuously) and make the map focus on that
            // location.
            LocationManager.shared.locateFromGPS(.oneShot, accuracy: .city) { result in
                switch result {
                case let .failure(error):
                    Log("Received error: \(error)")
                case let .success(location):
                    Log("Location received: \(location)")
                    self.setMapCentre(coordinate: location.coordinate)
                }
            }
        }
    }
}

// MARK: FloatingPanelControllerDelegate

extension ViewController: FloatingPanelControllerDelegate {
    // This method should be called whenever the device orientation is changed.
    // This is the method that will be called by the .updateLayout() method from
    // before.
    func floatingPanel(_ vc: FloatingPanelController, layoutFor _: UITraitCollection) -> FloatingPanelLayout? {
        if vc.contentViewController?.className == "TimesPanelViewController" {
            Log(UIDevice.current.orientation.isLandscape)
            // If the content view controller is called "TimesPanelViewController",
            // then if the device is in landscape then use the
            // TimesPanelLandscapeLayout(). If not use the
            // TimesPanelLayout(). These two classes just tell the content
            // view controller how to layout the view.
            return (UIDevice.current.orientation.isLandscape) ? TimesPanelLandscapeLayout() : TimesPanelLayout()
        } else if vc.contentViewController?.className == "SearchPanelViewController" {
            // If the content view controller is called "SearchPanelViewController",
            // then use SearchPanelLayout() regarless of orientation.
            return SearchPanelLayout()
        } else {
            // If the content view controller is called neither then just use
            // default. This shouldn't happen though.
            return nil
        }
    }
}

// MARK: CellTapDelegate

extension ViewController: CellTapDelegate {
    func cellTapped(matchingItem: MKMapItem) {
        // This is called when a cell in the search panel is tapped.
        if addAnnotation(item: matchingItem) != nil {
            // If the map item is successfully added as an annotation, then make
            // the map focus on that location and reload the table view of the times
            // panel (so it shows the new location).
            setMapCentre(coordinate: matchingItem.placemark.coordinate)
            contentVC?.tableView.reloadData()
        }
    }
}

// MARK: MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    // This is similar to the method for table views that sets up the cells.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? CustomAnnotationClass else { return nil }

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView")

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
        }

        var image: UIImage
        if #available(iOS 13.0, *) {
            // If the device has an iOS version of 13 or later use the SF Symbols
            // symbol of the number in a filled circle.
            image = UIImage(systemName: String(annotation.id) + ".circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .medium))!
        } else {
            // Otherwise use the bitmap (png).
            image = UIImage(named: String(annotation.id) + ".circle.fill-image")!
        }
        
        // Scale the images size to 50x50.
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        annotationView?.image = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        // Some other configuration.
        annotationView?.contentMode = .scaleAspectFit
        annotationView?.backgroundColor = .white
        annotationView?.clipsToBounds = true
        annotationView?.layer.cornerRadius = 25

        // Stop the annotation from showing a callout.
        annotationView?.canShowCallout = false

        return annotationView
    }

    // This method is called when any annotation is selected (or tapped).
    func mapView(_: MKMapView, didSelect view: MKAnnotationView) {
        Log("the annotation was selected")
        // If the annotation is not the devices location's annotation, then...
        if let annotation = view.annotation as? CustomAnnotationClass {
            // ... then move the floating panel's position to full and...
            fpc.move(to: .full, animated: true)
            // ... scroll the table view to the annotation's corresponding cell.
            contentVC?.tableView.scrollToRow(at: IndexPath(row: annotation.id - 1, section: 0), at: .top, animated: true)
        } else {}
    }
}

// MARK: UIGestureRecognizerDelegate

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: RemoveAnnotationDelegate

extension ViewController: RemoveAnnotationDelegate {
    func removeAnnotation(id: Int) {
        // Delete the location off coredata.
        LocationStore().delete(id: id)
        
        Log("success")
        
        // Reload the annotations.
        loadAnnotations()
        
        // Reload the table view of the floating panel.
        contentVC?.tableView.reloadData()
    }
}

// MARK: SetMapCentreDelegate

extension ViewController: SetMapCentreDelegate {
    func setMapCentre(coordinate: CLLocationCoordinate2D) {
        // Later you could make this more advanced with stuff from here: https://stackoverflow.com/questions/15421106/centering-mkmapview-on-spot-n-pixels-below-pin
        
        // Move the the floating panel to the tip position.
        fpc.move(to: .tip, animated: true)
        
        // Set the center of the map to the coordinate parameter.
        mapView.setCenter(coordinate, animated: true)
    }
}

// MARK: CustomAnnotationClass

class CustomAnnotationClass: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var id: Int

    init(id: Int, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
}

// MARK: Protocols

protocol RemoveAnnotationDelegate {
    func removeAnnotation(id: Int)
}

protocol SetMapCentreDelegate {
    func setMapCentre(coordinate: CLLocationCoordinate2D)
}

protocol CellTapDelegate: AnyObject {
    func cellTapped(matchingItem: MKMapItem)
}
