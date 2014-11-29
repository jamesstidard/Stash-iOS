//
//  EntropyHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation


protocol EntropyHarvester {
    
    var isRunning: Bool { get }
    weak var registeredEntropyMachine: EntropyMachine? { get set }
    
    init(machine: EntropyMachine)
    
    func start()
    func stop()
}

/**
*  Handles threadsafe access to properties for subclassed harvesters.
*/
class EntropyHarvesterBase: EntropyHarvester {
    
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
            self.queue.addOperationWith(qualityOfService: .UserInitiated,
                                                priority: .VeryHigh,
                                       waitUntilFinished: true) { () -> Void in
                result = self.running
            }
            return result
        }
    }
    
    // Holds the entropy machine the harvester is registered with and will send entropy to
    final private weak var entropyMachine: EntropyMachine? = nil
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
        newQueue.name             = "Entropy Harvester Core Motion Queue"
        newQueue.qualityOfService = .Background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    required init(machine: EntropyMachine) {
        self.registeredEntropyMachine = machine
    }
    
    func start() {
        fatalError("Entropy Harvester Base is a abstract class and should be subclassed.")
    }
    
    func stop() {
        fatalError("Entropy Harvester Base is a abstract class and should be subclassed.")
    }
}