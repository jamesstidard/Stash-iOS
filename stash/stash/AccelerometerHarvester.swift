//
//  CoreMotionAccelerometerHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

class AccelerometerHarvester: EntropyHarvesterBase {
    
    private let motionManager: CMMotionManager = {
        var newMotionManager = CMMotionManager.sharedInstance
        newMotionManager.accelerometerUpdateInterval = 0.1
        return newMotionManager
        }()
    
    
    convenience init (updateInterval :NSTimeInterval) {
        self.init()
        motionManager.accelerometerUpdateInterval = updateInterval
    }
    
    
    override func start() {
        self.isRunning = true
        
        self.motionManager.startAccelerometerUpdatesToQueue(self.queue, withHandler: { (data, error) -> Void in
            if error == nil {
                var (x, y, z) = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
                let data      = NSData.dataFromMultipleObjects([x, y, z])
                
                self.registeredEntropyMachine?.addEntropy(data)
            }
            else {
                self.stop()
            }
        })
    }
    
    override func stop() {
        self.motionManager.stopAccelerometerUpdates()
        self.isRunning = false
    }
}


