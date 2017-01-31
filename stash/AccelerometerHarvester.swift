//
//  CoreMotionAccelerometerHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion

final class AccelerometerHarvester: EntropyHarvester {
    
    // MARK: - Properties
    // Holds the current state of the harvester
    final fileprivate var running = false
    // A thread safe accessor for running property
    final var isRunning: Bool {
        set {
            self.queue.safelySet { () -> Void in
                self.running = newValue
            }
        }
        get {
            var result: Bool!
            self.queue.addOperationWith(qualityOfService: .userInitiated,
                priority: .veryHigh,
                waitUntilFinished: true) { () -> Void in
                    result = self.running
            }
            return result
        }
    }
    
    // Holds the entropy machine the harvester is registered with and will send entropy to
    fileprivate weak var entropyMachine: EntropyMachine? = nil
    // A thread safe accessor for entropy machine property
    final weak var registeredEntropyMachine: EntropyMachine? {
        set {
            self.queue.safelySet { () -> Void in
                self.entropyMachine = newValue
            }
        }
        get {
            var result: EntropyMachine?
            let operationBlock = BlockOperation { () -> Void in
                result = self.entropyMachine
            }
            operationBlock.qualityOfService = .userInitiated
            operationBlock.queuePriority    = .veryHigh
            self.queue.addOperations([operationBlock], waitUntilFinished: true)
            return result
        }
    }
    
    final lazy var queue: OperationQueue = {
        var newQueue              = OperationQueue()
        newQueue.name             = "Entropy Harvester Core Motion Accelerometer Queue"
        newQueue.qualityOfService = .background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()

    fileprivate let motionManager = CMMotionManager.sharedInstance
    
    
    
    // MARK: - Initalisers
    required init (machine: EntropyMachine) {
        self.entropyMachine = machine
        motionManager.accelerometerUpdateInterval = 1.0
    }

    convenience init (machine: EntropyMachine, updateInterval: TimeInterval) {
        self.init(machine: machine)
        motionManager.accelerometerUpdateInterval = updateInterval
    }
    
    // MARK: - Instance Functions
    func start() {
        self.isRunning = true
        
        self.motionManager.startAccelerometerUpdates(to: self.queue, withHandler: { (data, error) -> Void in
            if error == nil {
                var (x, y, z) = (data?.acceleration.x, data?.acceleration.y, data?.acceleration.z)
                let bytesToUse = (MemoryLayout<Double>.size/2) - 1 // least significant half, minus signing bit
                let data = Data.data(usingLeastSignificantBytes: bytesToUse, fromValues: [x,y,z], excludeSign: true)
                self.entropyMachine?.addEntropy(data)
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


