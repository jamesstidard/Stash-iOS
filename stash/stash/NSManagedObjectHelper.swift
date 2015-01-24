//
//  NSManagedObjectHelper.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

extension NSManagedObject {
    
    class func managedObjectWithEntityName(let name: String, let predicate: NSPredicate, let context: NSManagedObjectContext) -> NSManagedObject?
    {
        let fetchRequest        = NSFetchRequest(entityName: name)
        fetchRequest.predicate  = predicate
        fetchRequest.fetchLimit = 1; // only fetch one
        
        let results = context.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject]
        
        return results?.last
    }
}