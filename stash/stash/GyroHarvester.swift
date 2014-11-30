//
//  CoreMotionGyroHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

final class GyroHarvester: EntropyHarvester {
    
    // MARK: - Properties
    // Holds the current state of the harvester
    final private var running = false
    // A thread safe accessor for running property
    final var isRunning: Bool {
        set {
            self.queue.safelySet { () -> Void in
                self.running = newValue
            }
        }
        get {
            var result: Bool!
            self.queue.addOperationWith(
                qualityOfService: .UserInitiated,
                priority: .VeryHigh,
                waitUntilFinished: true) { () -> Void in
                    result = self.running
            }
            return result
        }
    }
    
    // Holds the entropy machine the harvester is registered with and will send entropy to
    private weak var entropyMachine: EntropyMachine? = nil
    // A thread safe accessor for entropy machine property
    final weak var registeredEntropyMachine: EntropyMachine? {
        set {
            self.queue.safelySet { () -> Void in
                self.entropyMachine = newValue
            }
        }
        get {
            var result: EntropyMachine?
            let operationBlock = NSBlockOperation { () -> Void in
                result = self.entropyMachine
            }
            operationBlock.qualityOfService = .UserInitiated
            operationBlock.queuePriority    = .VeryHigh
            self.queue.addOperations([operationBlock], waitUntilFinished: true)
            return result
        }
    }
    
    final lazy var queue: NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Entropy Harvester Core Motion Gyro Queue"
        newQueue.qualityOfService = .Background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    private let motionManager = CMMotionManager.sharedInstance
    
    
    
    // MARK: - Initilisers
    required init (machine: EntropyMachine) {
        self.entropyMachine = machine
        motionManager.gyroUpdateInterval = 1.0
    }
    
    convenience init (machine: EntropyMachine, updateInterval: NSTimeInterval) {
        self.init(machine: machine)
        motionManager.gyroUpdateInterval = updateInterval
    }
    
    // MARK: - Instance Functions
    func start() {
        self.isRunning = true
        
        self.motionManager.startGyroUpdatesToQueue(self.queue, withHandler: { (data, error) -> Void in
            if error == nil {
                var (x, y, z) = (data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
                let bytesToUse = (sizeof(Double)/2) - 1 // least significant half, minus signing bit
                let data = NSData.data(usingLeastSignificantBytes: bytesToUse, fromValues: [x,y,z], excludeSign: true)
                self.entropyMachine?.addEntropy(data)
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