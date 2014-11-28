//
//  CoreMotionGyroHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

class GyroHarvester {
    
    var isRunning: Bool = false
    weak var registeredEntropyMachine: EntropyMachine? = nil
    private let motionManager: CMMotionManager = {
        var newMotionManager = CMMotionManager.sharedInstance
        newMotionManager.gyroUpdateInterval = 0.1
        return newMotionManager
        }()
    
    private lazy var queue: NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Entropy Harvester Core Motion Gyro Queue"
        newQueue.qualityOfService = .Background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    
    required init (updateInterval :NSTimeInterval) {
        motionManager.gyroUpdateInterval = updateInterval
    }
    
    
    func start() {
        self.isRunning = true
        
        self.motionManager.startGyroUpdatesToQueue(self.queue, withHandler: { (data, error) -> Void in
            
            if error == nil {
                var (x, y, z) = (data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
                
                let data = NSData.dataFromMultipleObjects([x, y, z])
                
                self.registeredEntropyMachine?.addEntropy(data)
            }
            else {
                self.stop()
            }
        })
    }
    
    func stop() {
        self.motionManager.stopGyroUpdates()
        self.isRunning = false
    }
}