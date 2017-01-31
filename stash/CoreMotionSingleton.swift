//
//  CoreMotionSingleton.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

extension CMMotionManager {
    
    class var sharedInstance :CMMotionManager {
        struct Singleton {
            static let instance = CMMotionManager()
        }
        return Singleton.instance
    }
}