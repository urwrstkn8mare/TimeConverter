//
//  Backend.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 6/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class BackendSearchLocations {
    
    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil
    
    public func updateMatchingItems(text: String, completion: (() -> Void)? = nil) {
        
        guard let mapView = mapView else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("updateMatchingItems() - Error : \(error?.localizedDescription ?? "Unknown error").")
                return
            }
            
            self.matchingItems = response.mapItems
            
            // debugging
            print(self.matchingItems)
            
            if completion != nil {
                completion!()
            }
        }
        
        
        
    }
    
    public func parseAddress(selectedItem:MKPlacemark) -> String {
        
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
    
}

struct LocationStruct {
    let id: Int
    let location: MKMapItem
}

class LocationStore {
    
    public func read(id: Int? = nil) -> [LocationStruct] {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        
        if id != nil {
            fetchRequest.predicate = NSPredicate(format: "id = %@", id! as NSNumber)
        }
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if id == nil {
                var returnArray: [LocationStruct] = []
                for data in (result as! [NSManagedObject]) {
                    returnArray.append(LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: data.value(forKey: "latitude") as! Double, longitude: data.value(forKey: "longtitude") as! Double)))))
                }
                return returnArray
            } else {
                let data = (result as! [NSManagedObject])[0]
                return [LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: data.value(forKey: "latitude") as! Double, longitude: data.value(forKey: "longtitude") as! Double))))]
            }
        } catch {
            print("Read Failed")
            return []
        }
        // (result as! [NSManagedObject])
    }
    
    public func create(locationParam: MKMapItem) -> Int? {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let managedContext = appDelegate.persistentContainer.viewContext
        let locationEntity = NSEntityDescription.entity(forEntityName: "LocationEntity", in: managedContext)!
        
        let location = NSManagedObject(entity: locationEntity, insertInto: managedContext)
        location.setValue(locationParam.placemark.coordinate.longitude, forKey: "longtitude")
        location.setValue(locationParam.placemark.coordinate.latitude, forKey: "latitude")
        
        let newId = read().map{$0.id}.max()! + 1
        
        location.setValue(Double(newId), forKey: "id")
        
        do {
            try managedContext.save()
            return newId
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
            return nil
        }
        
    }
    
    public func update(id: Int, newLocation: MKMapItem? = nil, newId: Int? = nil) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id as NSNumber)
        
        if newLocation != nil && newId != nil {
            do {
                let test = try managedContext.fetch(fetchRequest)
                
                let object = test[0] as! NSManagedObject
                
                if newLocation != nil {
                    object.setValue(Double((newLocation!.placemark.coordinate.latitude)), forKey: "latitude")
                    object.setValue(Double((newLocation!.placemark.coordinate.longitude)), forKey: "longtitude")
                }
                
                if newId != nil {
                    object.setValue(Double(newId!), forKey: "id")
                }
                
                do {
                    try managedContext.save()
                } catch {
                    print(error)
                }
                
            } catch {
                print(error)
            }
        }
        
    }
    
    public func delete(id: Int) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id as NSNumber)
        
        do {
            let test = try managedContext.fetch(fetchRequest)
        
            let object = test[0] as! NSManagedObject
            
            managedContext.delete(object)
            
            for location in read() {
                if location.id > id {
                    update(id: location.id, newId: location.id - 1)
                }
            }
            
            do {
                try managedContext.save()
            } catch {
                print(error)
            }
            
        } catch {
                print(error)
        }
        
    }
    
}
