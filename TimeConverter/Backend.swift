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
    
    public private(set) var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil
    
    func updateMatchingItems(text: String, completion: (() -> Void)? = nil) {
        
        guard let mapView = mapView else {
            print("mapView not set")
            return
        }
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
    
    class func parseAddress(selectedItem:MKPlacemark) -> String {
        
        return "\(selectedItem.thoroughfare ?? ""), \(selectedItem.locality ?? ""), \(selectedItem.subLocality ?? ""), \(selectedItem.administrativeArea ?? ""), \(selectedItem.postalCode ?? ""), \(selectedItem.country ?? "")"
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
//                    CLLocation(latitude: CLLocationDegrees(exactly: data.value(forKey: "latitude") as! Double)!, longitude: CLLocationDegrees(exactly: data.value(forKey: "longtitude") as! Double)!).geocode() { (placemark, error) in
//                        if let error = error as? CLError {
//                            print("CLError:", error)
//                            return
//                        } else if let placemark = placemark?.first {
//                            returnArray.append(LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: MKMapItem(placemark: MKPlacemark(placemark: placemark))))
//                            if data == (result as! [NSManagedObject]).last {
//                                completionHandler(returnArray)
//                            }
//                        }
//                    }
                    
                    guard let decodedMapItem = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data.value(forKey: "mapItem") as! Data) as? MKMapItem else { return [] }
                    returnArray.append(LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: decodedMapItem))
                }
                print(returnArray)
                return returnArray
            } else {
                let data = (result as! [NSManagedObject])[0]
                
//                var mapItem: MKMapItem?
//                CLLocation(latitude: CLLocationDegrees(exactly: data.value(forKey: "latitude") as! Double)!, longitude: CLLocationDegrees(exactly: data.value(forKey: "longtitude") as! Double)!).geocode() { (placemark, error) in
//                    if let error = error as? CLError {
//                        print("CLError:", error)
//                        return
//                    } else if let placemark = placemark?.first {
//                        mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
//                        completionHandler([LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: mapItem!)])
//                    }
//                }
                
                
                guard let decodedMapItem = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data.value(forKey: "mapItem") as! Data) as? MKMapItem else { return [] }
                return [LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: decodedMapItem)]
                
            }
        } catch {
            print("Read Failed")
            return []
        }
        // (result as! [NSManagedObject])
    }
    
    public func create(locationParam: MKMapItem) -> Int?{
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let managedContext = appDelegate.persistentContainer.viewContext
        let locationEntity = NSEntityDescription.entity(forEntityName: "LocationEntity", in: managedContext)!
        
        let location = NSManagedObject(entity: locationEntity, insertInto: managedContext)
        
        if #available(iOS 11.0, *) {
            do {
                let mapItem = try NSKeyedArchiver.archivedData(withRootObject: locationParam, requiringSecureCoding: false)
                location.setValue(mapItem, forKey: "mapItem")
            } catch {
                print("cant encode data")
            }
        } else {
            let mapItem = NSKeyedArchiver.archivedData(withRootObject: locationParam)
            location.setValue(mapItem, forKey: "mapItem")
        }
        
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
                    
                    if #available(iOS 11.0, *) {
                        do {
                            let mapItem = try NSKeyedArchiver.archivedData(withRootObject: newLocation!, requiringSecureCoding: false)
                            object.setValue(mapItem, forKey: "mapItem")
                        } catch {
                            print("cant encode data")
                        }
                    } else {
                        let mapItem = NSKeyedArchiver.archivedData(withRootObject: newLocation!)
                        object.setValue(mapItem, forKey: "mapItem")
                    }
                    
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
                    self.update(id: location.id, newId: location.id - 1)
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

// To get name of class
extension UIViewController {
    var className: String {
        return NSStringFromClass(self.classForCoder).components(separatedBy: ".").last!
    }
}

// Adapted from https://stackoverflow.com/a/46869540
extension CLLocation {
    func geocode(completion: @escaping (_ placemark: [CLPlacemark]?, _ error: Error?) -> Void)  {
        CLGeocoder().reverseGeocodeLocation(self, completionHandler: completion)
    }
}
