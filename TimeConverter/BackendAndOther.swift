//
//  Backend.swift
//  TimeConverter
//
//  Created by Samit Shaikh on 6/11/19.
//  Copyright © 2019 Samit Shaikh. All rights reserved.
//

import CoreData
import Foundation
import MapKit

// MARK: LocationStruct
// This struct is the type that is how the locations are stored.
struct LocationStruct {
    let id: Int
    let location: MKMapItem
}

// MARK: LocationStore
class LocationStore {
    public func read(id: Int? = nil) -> [LocationStruct] {
        // Create a request to interface with coredata data.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        
        // If and id was specified than tell core data to look for a particular
        // item with a particular id.
        if id != nil {
            fetchRequest.predicate = NSPredicate(format: "id = %@", id! as NSNumber)
        }

        do {
            // Make the request and store the result.
            let result = try managedContext.fetch(fetchRequest)
            
            // If no id was specified...
            if id == nil {
                // Initialise an array of type LocationStruct.
                var returnArray: [LocationStruct] = []
                // Iterate over the items returned by the request.
                for data in result as! [NSManagedObject] {
                    // Decode the map item (it had to be encoded when it was created
                    // because coredata does not support MKMapItem) so it is stored
                    // in raw bytes.
                    guard let decodedMapItem = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data.value(forKey: "mapItem") as! Data) as? MKMapItem else { return [] }
                    
                    // Create a LocationStruct with the id and the decoded map item
                    // of the current item and append it to the returnArray array.
                    returnArray.append(LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: decodedMapItem))
                }
                
                // Return the returnArray.
                return returnArray
            // If an id was specified...
            } else {
                Log("result: \(result)")
                
                // Store the the item with the particular id.
                let data = result[0] as! NSManagedObject

                // (Explained this above).
                guard let decodedMapItem = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data.value(forKey: "mapItem") as! Data) as? MKMapItem else { return [] }
                
                // Return an array with one item that is a LocationStruct with the
                // id and decoded map item of the item.
                return [LocationStruct(id: Int(data.value(forKey: "id") as! Double), location: decodedMapItem)]
            }
        } catch {
            // If the request failed for some reason than put it in the console.
            Log("Read Failed")
            return []
        }
    }

    public func create(locationParam: MKMapItem) -> Int? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let managedContext = appDelegate.persistentContainer.viewContext
        let locationEntity = NSEntityDescription.entity(forEntityName: "LocationEntity", in: managedContext)!
        
        // Create a new item that will eventually be saved into core data.
        let location = NSManagedObject(entity: locationEntity, insertInto: managedContext)

        // Encode the map item into raw bytes and set it in the item.
        if #available(iOS 11.0, *) {
            do {
                let mapItem = try NSKeyedArchiver.archivedData(withRootObject: locationParam, requiringSecureCoding: false)
                location.setValue(mapItem, forKey: "mapItem")
            } catch {
                Log("cant encode data")
            }
        } else {
            let mapItem = NSKeyedArchiver.archivedData(withRootObject: locationParam)
            location.setValue(mapItem, forKey: "mapItem")
        }

        // Set the new id of the item to be one more than the biggest number of
        // all the items.
        let newId = read().map { $0.id }.max()! + 1
        location.setValue(Double(newId), forKey: "id")

        do {
            // Try to save the new item to core data.
            try managedContext.save()
            return newId
        } catch let error as NSError {
            Log("Could not save. \(error), \(error.userInfo)")
            return nil
        }
    }

    public func update(id: Int, newLocation: MKMapItem?, newId: Int?) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        
        // Tell coredata what item we are looking for by giving it an id to filter
        // the items with.
        fetchRequest.predicate = NSPredicate(format: "id = %@", id as NSNumber)

        // If both newLocation and newId were not specified then don't...
        if !(newLocation == nil && newId == nil) {
            do {
                // Make a request to coredata to get the item.
                let result = try managedContext.fetch(fetchRequest)
                let object = result[0] as! NSManagedObject

                if newLocation != nil {
                    // If a newLocation was specified then update the mapitem value with the newly encoded
                    // mapitem.
                    if #available(iOS 11.0, *) {
                        do {
                            let mapItem = try NSKeyedArchiver.archivedData(withRootObject: newLocation!, requiringSecureCoding: false)
                            object.setValue(mapItem, forKey: "mapItem")
                        } catch {
                            Log("cant encode data")
                        }
                    } else {
                        let mapItem = NSKeyedArchiver.archivedData(withRootObject: newLocation!)
                        object.setValue(mapItem, forKey: "mapItem")
                    }
                }

                if newId != nil {
                    // If a newId was specified then set the id value of the item
                    // to newId.
                    object.setValue(Double(newId!), forKey: "id")
                }

                do {
                    // Try to save the updated item.
                    try managedContext.save()
                    
                    Log("before update read")
                    Log("read:")
                    Log(read(id: newId))
                    Log("after update read")
                } catch {
                    Log(error)
                }

            } catch {
                Log(error)
            }
        }
    }

    public func delete(id: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        
        // Tell coredata what we are looking for.
        fetchRequest.predicate = NSPredicate(format: "id = %@", id as NSNumber)

        do {
            // Get the object (item) we want by requesting it.
            let test = try managedContext.fetch(fetchRequest)
            let object = test[0] as! NSManagedObject

            // Before we can delete it lets move the items down to take the place of
            // the item we are about to delete.
            for location in read() {
                Log("first read success")
                if location.id > id {
                    update(id: location.id, newLocation: nil, newId: location.id - 1)
                }
            }

            // Delete the object (item).
            managedContext.delete(object)

            do {
                // Try to save the changes.
                try managedContext.save()
            } catch {
                Log(error)
            }

        } catch {
            Log(error)
        }
    }
}

// MARK: className
// This extension of UIViewController just allows you to get the name of it with a
// simple method.
extension UIViewController {
    var className: String {
        return NSStringFromClass(classForCoder).components(separatedBy: ".").last!
    }
}

// MARK: Log
public func Log<T>(_ object: T?, filename: String = #file, line: Int = #line, funcname: String = #function) {
    #if DEBUG
        guard let object = object else { return }
        print("***** \(Date()) | \(filename.components(separatedBy: "/").last ?? "") (line: \(line)) :: \(funcname) :: \(object)")
    #endif
}
