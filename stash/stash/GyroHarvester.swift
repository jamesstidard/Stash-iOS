//
//  CoreMotionGyroHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

class GyroHarvester {
    
    // Holds the current state of the harvester
    private var running = false
    // A thread safe accessor for running property
    var isRunning: Bool {
        set {
            GyroHarvester.safelySet(&self.running, toValue: newValue, onQueue: self.queue)
        }
        get {
            return GyroHarvester.safelyGet(self.running, onQueue: self.queue)
        }
    }
    
    // Holds the entropy machine the harvester is registered with and will send entropy to
    private weak var entropyMachine: EntropyMachine? = nil
    // A thread safe accessor for entropy machine property
    weak var registeredEntropyMachine: EntropyMachine? {
        set {
            GyroHarvester.safelySet(&entropyMachine, toValue: newValue, onQueue: self.queue)
        }
        get {
            return GyroHarvester.safelyGet(self.entropyMachine, onQueue: self.queue)
        }
    }
    
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
    
    private class func safelySet<T>(inout value: T, toValue: T, onQueue queue: NSOperationQueue) {
        let setOperation = NSBlockOperation { () -> Void in
            value = toValue
        }
        setOperation.qualityOfService = .UserInitiated
        setOperation.queuePriority    = .VeryHigh
        
        queue.addOperation(setOperation)
    }
    
    private class func safelyGet<T>(value: T, onQueue queue: NSOperationQueue) -> T {
        var result: T!
        let getOperation = NSBlockOperation { () -> Void in
            result = value
        }
        getOperation.qualityOfService = .UserInitiated
        getOperation.queuePriority    = .VeryHigh
        
        queue.addOperations([getOperation], waitUntilFinished: true)
        
        return result
    }
    
    
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