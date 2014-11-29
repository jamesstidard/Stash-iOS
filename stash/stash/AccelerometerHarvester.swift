//
//  CoreMotionAccelerometerHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

class AccelerometerHarvester: EntropyHarvesterBase {
    
    private let motionManager = CMMotionManager.sharedInstance
    
    required init (machine: EntropyMachine) {
        motionManager.accelerometerUpdateInterval = 0.1
        super.init(machine: machine)
    }

    convenience init (machine: EntropyMachine, updateInterval: NSTimeInterval) {
        self.init(machine: machine)
        motionManager.accelerometerUpdateInterval = updateInterval
    }
    
    override func start() {
        self.isRunning = true
        
        self.motionManager.startAccelerometerUpdatesToQueue(self.queue, withHandler: { (data, error) -> Void in
            if error == nil {
                var (x, y, z) = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
                let bytesToUse = (sizeof(Double)/2) - 1 // least significant half, minus signing bit
                let data = NSData.data(usingLeastSignificantBytes: bytesToUse, fromValues: [x,y,z], excludeSign: true)
                println("accel sent: \(data)")
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


