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
// Date of last revision: 27/11/2019 (you should just check git though)

// Notes:
//  - Ignore any Log() functions they are just for my own debugging use.

// The above covered:
//  - ViewController.swift
//  - TimesPanelViewController.swift
//  - SearchPanelViewController.swift
//  - BackendAndOther.swift

// Apple's Stuff
import UIKit
import MapKit
import CoreLocation
import Foundation
// Third party pods
import FloatingPanel // https://github.com/SCENEE/FloatingPanel
import SwiftLocation // https://github.com/malcommac/SwiftLocation
import SwiftyPickerPopover // https://github.com/hsylife/SwiftyPickerPopover

// MARK: ViewController
class ViewController: UIViewController {
    
    // Outlets (from storyboard).
    @IBOutlet weak var sideButtons: UIVisualEffectView!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var locationIconView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchIconImageView: UIImageView!
    @IBOutlet weak var locationIconImageView: UIImageView!
    
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
            sideButtons.layer.borderColor = UIColor(red: 198.0/255.0, green: 198.0/255.0, blue: 200.0/255.0, alpha: 1.0).cgColor
        }
        
        // Initially settings up the position of the sidebuttons on the y-axis.
        sideButtons.frame = CGRect(x: sideButtons.frame.minX, y: ((UIScreen.main.bounds.height / 2) - 20 - sideButtons.frame.height), width: sideButtons.frame.width, height: sideButtons.frame.height)
        
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
        
        // Another custom delegate to facilliate communication.
        searchContentVC.cellTapDelegate = self
        
        // Setting the content view controller to the initialised content view
        // controller.
        fpcSearch.set(contentViewController: searchContentVC)
        
        // Find out about this method at the method definition.
        loadAnnotations()
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            
            let isLandscape = UIDevice.current.orientation.isLandscape
            let isIpad = UIDevice.current.userInterfaceIdiom == .pad ? true : false
            let bounds = UIScreen.main.bounds
            var width: CGFloat?
            var height: CGFloat?
            
            if isIpad {
                width = bounds.width
                height = bounds.height
            } else {
                width = bounds.height
                height = bounds.width
            }
            
            Log(isLandscape)
            Log(isIpad)
            Log(width)
            Log(height)
            Log("-------------")
            
            if isLandscape {
                sideButtons.frame = CGRect(x: sideButtons.frame.minX, y: ((height! / 2) - (sideButtons.frame.height / 2)), width: sideButtons.frame.width, height: sideButtons.frame.height)
            } else {
                sideButtons.frame = CGRect(x: sideButtons.frame.minX, y: ((height! / 2) - 20 - sideButtons.frame.height), width: sideButtons.frame.width, height: sideButtons.frame.height)
            }
            
            fpc.updateLayout()
        }
    
    @objc func mapViewLongPress(recogniser: UIGestureRecognizer) {
            if recogniser.state == UIGestureRecognizer.State.began {
                let touchPoint = recogniser.location(in: mapView)
                let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                
                let newId = addAnnotation(item: MKMapItem(placemark: MKPlacemark(coordinate: newCoordinates)))
                if newId != nil {
                    LocationManager.shared.locateFromCoordinates(newCoordinates, service: .apple(GeocoderRequest.Options())) { result in
                      switch result {
                        case .failure(let error):
                          Log("Geoocoder Error: \(error)")
                        case .success(let places):
                            if let placemark = places.first?.placemark {
                                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                                LocationStore().update(id: newId!, newLocation: mapItem, newId: nil)
                                self.contentVC?.tableView.reloadData()
                            }
                      }
                    }

                }
                
            }
        }
    
    func loadAnnotations() {
        let locationStore = LocationStore()
        mapView.removeAnnotations(mapView.annotations)
        for locationStruct in locationStore.read() {
            let newAnnotation = CustomAnnotationClass(id:locationStruct.id, coordinate: locationStruct.location.placemark.coordinate)
            self.mapView.addAnnotation(newAnnotation)
        }
    }
    
    func addAnnotation(item: MKMapItem) -> Int? {
        
        let locationStore = LocationStore()
        
        let maxCount: Int
        if #available(iOS 13, *) {
            maxCount = 50
        } else {
            maxCount = 10
        }
        
        let result = locationStore.read()
        if result.count == maxCount {
            let alert = UIAlertController(title: "Too many locations!", message: "You can only create a maximum of \(maxCount) locations.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return nil
        } else {
            let distanceApartOtherAnnotationsMustBe: Int = 900000
                
            let newId = locationStore.create(locationParam: item)
            
            let newAnnotation = CustomAnnotationClass(id: newId!, coordinate: item.placemark.coordinate)
            
            self.mapView.addAnnotation(newAnnotation)
            
            for locationStruct in result {
                if (item.placemark.location?.distance(from: locationStruct.location.placemark.location!))! < Double(distanceApartOtherAnnotationsMustBe + 1) {
                    Log("too close")
                    
                    self.setMapCentre(coordinate: locationStruct.location.placemark.coordinate)
                    self.mapView.removeAnnotation(newAnnotation)
                    locationStore.delete(id: newId!)
                    
                    let alert = UIAlertController(title: "Too many close!", message: "Your location must be at least \(distanceApartOtherAnnotationsMustBe/1000)km away from any other location.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                    
                    return nil
                }
            }
            
            return newId
        }
        
    }
    
    @IBAction func handleSearchTap(recogniser:UITapGestureRecognizer) {
            // Show the user that the button has been tapped
            UIView.animate(withDuration: 0.1, animations: {
                () in
                if #available(iOS 13, *) {
                    self.searchIconView.backgroundColor = UIColor.opaqueSeparator
                } else {
                    self.searchIconView.backgroundColor = UIColor(red: 198.0/255.0, green: 198.0/255.0, blue: 200.0/255.0, alpha: 1.0)
                }
                self.searchIconView.alpha = 0.8
            }, completion: {
                (finished: Bool) in
                self.searchIconView.backgroundColor = .clear
                self.searchIconView.alpha = 1
            })
            
            self.present(fpcSearch, animated: true, completion: nil)
            
        }
    
        @IBAction func handleLocationTap(recogniser:UITapGestureRecognizer) {
            // Show the user that the button has been tapped
             UIView.animate(withDuration: 0.1, animations: { () in
                if #available(iOS 13, *) {
                    self.locationIconView.backgroundColor = UIColor.opaqueSeparator
                } else {
                    self.locationIconView.backgroundColor = UIColor(red: 198.0/255.0, green: 198.0/255.0, blue: 200.0/255.0, alpha: 1.0)
                }
                self.locationIconView.alpha = 0.8
             }, completion: { (finished: Bool) in
                self.locationIconView.backgroundColor = .clear
                self.locationIconView.alpha = 1
             })
            
            LocationManager.shared.requireUserAuthorization(.whenInUse)
            mapView.showsUserLocation = !mapView.showsUserLocation
            
            LocationManager.shared.locateFromGPS(.oneShot, accuracy: .city) { result in
              switch result {
                case .failure(let error):
                  Log("Received error: \(error)")
                case .success(let location):
                  Log("Location received: \(location)")
                  self.setMapCentre(coordinate: location.coordinate)
              }
            }
            
        }
    
}

// MARK: FloatingPanelControllerDelegate
extension ViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        if vc.contentViewController?.className == "TimesPanelViewController" {
            Log(UIDevice.current.orientation.isLandscape)
            return (UIDevice.current.orientation.isLandscape) ? TimesPanelLandscapeLayout() : TimesPanelLayout()
        } else if vc.contentViewController?.className == "SearchPanelViewController" {
            return SearchPanelLayout()
        } else {
            return nil
        }
    }
}

// MARK: CellTapDelegate
extension ViewController: CellTapDelegate {
    func cellTapped(matchingItem: MKMapItem) {
        if addAnnotation(item: matchingItem) != nil {
            mapView.setCenter(matchingItem.placemark.coordinate, animated: true)
            self.contentVC?.tableView.reloadData()
        }
    }
}

// MARK: MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotationClass else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView")
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
        }
        
        var image: UIImage
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: String(annotation.id) + ".circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .medium))!
        } else {
            // Fallback on earlier versions
            image = UIImage(named: String(annotation.id) + ".circle.fill-image")!
        }
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        annotationView?.image = renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        annotationView?.contentMode = .scaleAspectFit
        annotationView?.backgroundColor = .white
        annotationView?.clipsToBounds = true
        annotationView?.layer.cornerRadius = 25
        
        annotationView?.canShowCallout = false
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        Log("the annotation was selected")
        if let annotation = view.annotation as? CustomAnnotationClass {
            contentVC?.tableView.scrollToRow(at: IndexPath(row: annotation.id - 1, section: 0), at: .top, animated: true)
            fpc.move(to: .full, animated: true)
        } else {
            
        }
    }
}

// MARK: UIGestureRecognizerDelegate
extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: RemoveAnnotationDelegate
extension ViewController: RemoveAnnotationDelegate {
    func removeAnnotation(id: Int) {
        let locationStore = LocationStore()
        locationStore.delete(id: id)
        Log("success")
        loadAnnotations()
        contentVC?.tableView.reloadData()
    }
}

// MARK: SetMapCentreDelegate
extension ViewController: SetMapCentreDelegate {
    func setMapCentre(coordinate: CLLocationCoordinate2D) {
        // Later you could make this more advanced with stuff from here: https://stackoverflow.com/questions/15421106/centering-mkmapview-on-spot-n-pixels-below-pin
        fpc.move(to: .tip, animated: true)
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
