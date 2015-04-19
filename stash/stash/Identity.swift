//
//  Identity.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation
import CoreData

@objc(Identity)
class Identity: NSManagedObject {

    @NSManaged var lockKey: NSData
    @NSManaged var name: String
    @NSManaged var masterKey: XORStore
    @NSManaged var settings: Settings?
    @NSManaged var unlockKey: GCMStore

}
