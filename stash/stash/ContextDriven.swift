//
//  ContextDriven.swift
//  stash
//
//  Created by James Stidard on 13/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

@objc protocol ContextDriven {
    var context :NSManagedObjectContext? {get set}
}