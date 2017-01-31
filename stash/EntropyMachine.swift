//
//  EntropyMachine.swift
//  stash
//
//  Created by James Stidard on 06/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation


final class EntropyMachine {
    
    // Holds state of entropy machine (on/off)
    fileprivate var started: Bool = false
    
    // Holds the state of the open hash function (open/closed).
    fileprivate static let InitialState: crypto_hash_sha512_state = crypto_hash_sha512_state(
        state: (0, 0, 0, 0, 0, 0, 0, 0),
        count: (0, 0),
        buf: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    )
    fileprivate var state: crypto_hash_sha512_state = InitialState
    
    // Serial queue to enforce thread safe execution when called from multiple threads
    fileprivate lazy var queue: OperationQueue = {
        var newQueue              = OperationQueue()
        newQueue.name             = "Entropy Machine Queue"
        newQueue.qualityOfService = .background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    
    func start() {
        
        // Cancel any pending operations and start queue
        self.queue.cancelAllOperations()
        self.queue.isSuspended = false
        
        let startOperation = BlockOperation { () -> Void in
            // start the hash function (if not already started)
            if !self.started {
                // switch hash state to on
                self.started = true
                
                // start (open) hash function
                self.state = EntropyMachine.InitialState
                Sha512.openHash(&self.state)
                
                // Input initial entropy
                self.addRandomBytesToHash()
                self.addSystemDateTimeToHash()
                self.addProccessIdToHash()
                self.addSystemUpTimeToHash()
            }
        }
        
        self.queue.addOperationWith(qualityOfService: .userInitiated,
                                            priority: .veryHigh,
                                   waitUntilFinished: false,
                                      operationBlock: startOperation)
    }
    
    func addEntropy(_ entropy: Data) {
        
        // Holds a queue with a max of 10 operations
        // excess entropy data is discarded
        if self.queue.operationCount > 10 { return }
        
        self.queue.addOperation { () -> Void in
            if self.started {
                Sha512.updateHash(&self.state, data: entropy)
            }
        }
    }
    
    func stop() -> Data? {
        
        var result: Data?
        
        if self.queue.isSuspended {
            return result
        }
        
        let stopOperation = BlockOperation { () -> Void in
            if self.started {
                result       = Sha512.closeHash(&self.state)
                self.started = false
            }
        }
        
        self.queue.addOperationWith(qualityOfService: .userInitiated,
                                            priority: .veryHigh,
                                   waitUntilFinished: true,
                                      operationBlock: stopOperation)
        
        self.queue.isSuspended = true
        
        return result
    }
    
    fileprivate func addRandomBytesToHash() {
        if let randomBuffer = SodiumUtilities.randomBytes(512) {
            Sha512.updateHash(&self.state, data: randomBuffer)
        }
    }
    
    fileprivate func addSystemDateTimeToHash() {
        var dateTime = Date().timeIntervalSince1970
        let data     = Data(bytes: UnsafePointer<UInt8>(&dateTime), count: sizeof(TimeInterval))
        
        Sha512.updateHash(&self.state, data: data)
    }
    
    fileprivate func addProccessIdToHash() {
        var processId = ProcessInfo().processIdentifier
        let data      = Data(bytes: UnsafePointer<UInt8>(&processId), count: sizeof(UInt32))
        
        Sha512.updateHash(&self.state, data: data)
    }
    
    fileprivate func addSystemUpTimeToHash() {
        var systemUpTime = ProcessInfo().systemUptime
        let data         = Data(bytes: UnsafePointer<UInt8>(&systemUpTime), count: sizeof(TimeInterval))
        
        Sha512.updateHash(&self.state, data: data)
    }
}
