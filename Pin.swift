//
//  Pin.swift
//  VirtualTourist
//
//  Created by Adam Zarn on 8/26/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    // Insert code here to add functionality to your managed object subclass
    convenience init(lat: Double, long: Double, context : NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.lat = lat
            self.long = long
        } else {
            fatalError("Unable to find Entity name!")
        }
        
    }
    
    
}
