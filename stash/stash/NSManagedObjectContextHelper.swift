//
//  NSManagedObjectContextHelper.swift
//  stash
//
//  Created by James Stidard on 17/03/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

extension NSManagedObjectContext
{
    convenience init(concurrencyType: NSManagedObjectContextConcurrencyType, parentContext parent: NSManagedObjectContext?)
    {
        self.init(concurrencyType: concurrencyType)
        self.parentContext = parent
    }
    
    func saveUpParentHierarchyAndWait(inout error: NSError?)
    {
        self.saveUpParentHierarchyAndWait(nil, error: &error)
    }
    
    func saveUpParentHierarchyAndWait(var parentLimit: Int?, inout error: NSError?)
    {
        self.performBlockAndWait {
            self.save(&error)
            println("saved context: \(self)")
            // Quit once parent limit reached; an error is produced; there are no more parent contexts
            if parentLimit == 0 || error != nil || self.parentContext == nil {
                return
            }
            
            self.parentContext!.saveUpParentHierarchyAndWait(parentLimit?--, error: &error)
        }
    }
}