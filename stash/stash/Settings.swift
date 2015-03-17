//
//  Settings.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation
import CoreData

class Settings: NSManagedObject {

    @NSManaged var hintLength: Int16
    @NSManaged var passwordVerificationLength: Int16
    @NSManaged var identity: Identity?

}