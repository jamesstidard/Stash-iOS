//
//  SecureStore.swift
//  stash
//
//  Created by James Stidard on 09/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

class SecureStore: NSManagedObject {
    @NSManaged var ciphertext: NSData
    @NSManaged var scryptIterations: Int64
    @NSManaged var scryptMemoryFactor: Int64
    @NSManaged var scryptSalt: NSData
    @NSManaged var verificationTag: NSData
}
