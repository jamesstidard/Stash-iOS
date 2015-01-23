//
//  Identity.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

class Identity: NSManagedObject {
    @NSManaged var name:      String
    @NSManaged var lockKey:   NSData
    @NSManaged var unlockKey: NSData
}
