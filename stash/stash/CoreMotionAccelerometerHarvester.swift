//
//  CoreMotionAccelerometerHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

class CoreMotionAccelerometerHarvester {
    
    var isRunning: Bool = false
    weak var registeredEntropyMachine: EntropyMachine? = nil
    private let motionManager: CMMotionManager = {
        var newMotionManager = CMMotionManager.sharedInstance
        newMotionManager.accelerometerUpdateInterval = 0.1
        return newMotionManager
        }()
    
    private lazy var queue: NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Entropy Harvester Core Motion Accelerometer Queue"
        newQueue.qualityOfService = .Background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    
    required init (updateInterval :NSTimeInterval) {
        motionManager.accelerometerUpdateInterval = updateInterval
    }
    
    
    func start() {
        self.isRunning = true
        
        self.motionManager.startAccelerometerUpdatesToQueue(self.queue, withHandler: { (data, error) -> Void in
            if error == nil {
                var (x, y, z) = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
                let xData = NSData(bytes: &x, length: sizeof(Double))
                let yData = NSData(bytes: &y, length: sizeof(Double))
                let zData = NSData(bytes: &z, length: sizeof(Double))
                
                var data = NSMutableData(data: xData)
                data.appendData(yData)
                data.appendData(zData)
                
                self.registeredEntropyMachine?.addEntropy(data)
            }
            else {
                self.stop()
            }
        })
    }
    
    func stop() {
        self.motionManager.stopAccelerometerUpdates()
        self.isRunning = false
    }
}
