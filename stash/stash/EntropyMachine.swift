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
    private var started: Bool = false
    
    // Holds the state of the open hash function (open/closed).
    private static let InitialState: crypto_hash_sha512_state = crypto_hash_sha512_state(
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
    private var state: crypto_hash_sha512_state = InitialState
    
    // Serial queue to enforce thread safe execution when called from multiple threads
    private lazy var queue: NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Entropy Machine Queue"
        newQueue.qualityOfService = .Background
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    
    func start() {
        
        // Cancel any pending operations and start queue
        self.queue.cancelAllOperations()
        self.queue.suspended = false
        
        let startOperation = NSBlockOperation { () -> Void in
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
        
        self.queue.addOperationWith(qualityOfService: .UserInitiated,
                                            priority: .VeryHigh,
                                   waitUntilFinished: false,
                                      operationBlock: startOperation)
    }
    
    func addEntropy(entropy: NSData) {
        
        // Holds a queue with a max of 10 operations
        // excess entropy data is discarded
        if self.queue.operationCount > 10 { return }
        
        self.queue.addOperationWithBlock { () -> Void in
            if self.started {
                Sha512.updateHash(&self.state, data: entropy)
            }
        }
    }
    
    func stop() -> NSData? {
        
        var result: NSData?
        
        if self.queue.suspended {
            return result
        }
        
        let stopOperation = NSBlockOperation { () -> Void in
            if self.started {
                result       = Sha512.closeHash(&self.state)
                self.started = false
            }
        }
        
        self.queue.addOperationWith(qualityOfService: .UserInitiated,
                                            priority: .VeryHigh,
                                   waitUntilFinished: true,
                                      operationBlock: stopOperation)
        
        self.queue.suspended = true
        
        return result
    }
    
    private func addRandomBytesToHash() {
        if let randomBuffer = SodiumUtilities.randomBytes(512) {
            Sha512.updateHash(&self.state, data: randomBuffer)
        }
    }
    
    private func addSystemDateTimeToHash() {
        var dateTime = NSDate().timeIntervalSince1970
        let data     = NSData(bytes: &dateTime, length: sizeof(NSTimeInterval))
        
        Sha512.updateHash(&self.state, data: data)
    }
    
    private func addProccessIdToHash() {
        var processId = NSProcessInfo().processIdentifier
        let data      = NSData(bytes: &processId, length: sizeof(UInt32))
        
        Sha512.updateHash(&self.state, data: data)
    }
    
    private func addSystemUpTimeToHash() {
        var systemUpTime = NSProcessInfo().systemUptime
        let data         = NSData(bytes: &systemUpTime, length: sizeof(NSTimeInterval))
        
        Sha512.updateHash(&self.state, data: data)
    }
}
