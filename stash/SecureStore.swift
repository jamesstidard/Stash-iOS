//
//  SecureStore.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation
import CoreData

@objc(SecureStore)
class SecureStore: NSManagedObject {

    @NSManaged var ciphertext: Data
    @NSManaged var scryptIterations: Int64
    @NSManaged var scryptMemoryFactor: Int64
    @NSManaged var scryptSalt: Data
    @NSManaged var verificationTag: Data

}
