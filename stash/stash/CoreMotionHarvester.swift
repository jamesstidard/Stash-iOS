//
//  CoreMotionHarvester.swift
//  stash
//
//  Created by James Stidard on 10/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation
import CoreMotion

class CoreMotionHarvester: EntropyHarvester {
    
    var isRunning: Bool
    weak var registeredEntropyMachine: EntropyMachine?
    private let motionManager = CMMotionManager()
    
    required init(registerWith entropyMachine: EntropyMachine) {
        self.registeredEntropyMachine = entropyMachine
        self.isRunning = false
    }
    
    func start() {
        
    }
    
    func stop() {
        
    }
}