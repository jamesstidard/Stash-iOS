//
//  CoreMotionHarvester.swift
//  stash
//
//  Created by James Stidard on 10/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

class CoreMotionHarvester: EntropyHarvester {
    
    var isRunning: Bool = false
    weak var registeredEntropyMachine: EntropyMachine? = nil
    private let motionManager: CMMotionManager = {
        var newMotionManager = CMMotionManager.sharedInstance
        newMotionManager.gyroUpdateInterval = 0.1
        return newMotionManager
    }()
    
    private lazy var queue: NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Entropy Harvester Core Motion Queue"
        newQueue.qualityOfService = .UserInitiated
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    
    required init (updateInterval :NSTimeInterval) {
        motionManager.gyroUpdateInterval = updateInterval
    }
    
    
    func start() {
        self.motionManager.startGyroUpdatesToQueue(self.queue, withHandler: { (data, error) -> Void in
            
            let motionString = "\(data.rotationRate.x)\(data.rotationRate.y)\(data.rotationRate.z)"

            if let motionData = motionString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                if let machine = self.registeredEntropyMachine {
                    machine.addEntropy(motionData)
                }
            }
        })
    }
    
    func stop() {
        self.motionManager.stopGyroUpdates()
    }
}