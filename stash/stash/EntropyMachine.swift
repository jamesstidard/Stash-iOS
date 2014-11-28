//
//  EntropyMachine.swift
//  stash
//
//  Created by James Stidard on 06/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation


class EntropyMachine {
    
    // Holds state of entropy machine (on/off)
    private var started: Bool = false
    
    // Holds the state of the open hash function (open/closed).
    private var state: crypto_hash_sha512_state = crypto_hash_sha512_state(
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
    
    // Serial queue to enforce thread safe execution when called from multiple threads
    private lazy var queue: NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Entropy Machine Queue"
        newQueue.qualityOfService = .UserInitiated
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    private lazy var harvesters = NSMutableArray()
    
    
    
    // Accepts anything that conforms to both AnyObject and EntropyHaverster
    /**
    Registers the harvester to the EntropyMachine by setting itself to the harvester's
    registeredEntropyMachine property. The harvester is then added to the EntropyMachines
    internal harvester list. Finally, if the EntropyMaching is running, the harvester's
    start() function is also called.
    
    Threadsafety:
    This fucntion is threadsafe. All is performed on an internal operation queue.
    The harvesters registeredEntropyMachine property should also be threadsafe.
    
    :param: harvester A object that conforms to AnyObject and EntropyHarvester protocols.
    Provides as a source of entropy to the EntropyMachine by calling it's addEntropy() function.
    */
    func addHarvester<H :AnyObject where H :EntropyHarvester>(inout harvester: H) {
        
        let addHarvesterOperation = NSBlockOperation { () -> Void in
            self.harvesters.addObject(harvester)
            harvester.registeredEntropyMachine = self
            
            // If hash is open start the harvester up to feed in entropy
            if self.started { harvester.start() }
        }
        
        self.queue.addOperationWith(qualityOfService: .UserInitiated,
                                            priority: .VeryHigh,
                                   waitUntilFinished: true,
                                      operationBlock: addHarvesterOperation)
    }
    
    /**
    Deregisters the harvester from the EntropyMachine by calling the stop() function on the
    harvester and removes itself from the harvester's reference to the machine. Finally,
    the harvester is removed from EntropyMachine's list maintainging all registered
    harvesters.
    
    Threadsafety:
    This fucntion is threadsafe. All is performed on an internal operation queue.
    The harvesters registeredEntropyMachine property should also be threadsafe.
    
    :param: harvester A object that conforms to AnyObject and EntropyHarvester protocols.
    Provides as a source of entropy to the EntropyMachine by calling it's addEntropy() function.
    */
    func removeHarvester<H :AnyObject where H :EntropyHarvester>(inout harvester: H) {
        
        // Operation block to be added to internal, serial operation queue.
        let removeHarvesterOperation = NSBlockOperation { () -> Void in
            
            // if this machine is the havesters registered machine: stop it harvesting and remove it.
            if let registeredEntropyMachine = harvester.registeredEntropyMachine {
                if ObjectIdentifier(registeredEntropyMachine) == ObjectIdentifier(self) {
                    harvester.stop()
                    harvester.registeredEntropyMachine = nil;
                }
            }
            
            // Remove from harvester list
            self.harvesters.removeObject(harvester)
        }
        
        self.queue.addOperationWith(qualityOfService: .UserInitiated,
                                            priority: .VeryHigh,
                                   waitUntilFinished: false,
                                      operationBlock: removeHarvesterOperation)
    }
    
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
                crypto_hash_sha512_init(&self.state)
                
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
                var entropyChars = UnsafePointer<CUnsignedChar>(entropy.bytes)
                crypto_hash_sha512_update(&self.state, entropyChars, UInt64(entropy.length))
            }
        }
    }
    
    func stop() -> NSData? {
        
        var result: NSData?
        
        let stopOperation = NSBlockOperation { () -> Void in
            if self.started {
                let charsCount = Int(crypto_hash_sha512_BYTES) / sizeof(CUnsignedChar)// number of chars in sha512
                var hash       = UnsafeMutablePointer<CUnsignedChar>.alloc(charsCount)
                
                crypto_hash_sha512_final(&self.state, hash)
                
                result       = NSData(bytes: hash, length: Int(crypto_hash_sha512_BYTES))
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
        let charsCount = Int(crypto_hash_sha512_BYTES) / sizeof(CUnsignedChar) // number of chars in sha512
        var random     = UnsafeMutablePointer<CUnsignedChar>.alloc(charsCount)
        
        randombytes_buf(random, UInt(crypto_hash_sha512_BYTES))
        crypto_hash_sha512_update(&self.state, random, UInt64(crypto_hash_sha512_BYTES))
        random.dealloc(charsCount)
    }
    
    private func addSystemDateTimeToHash() {
        var dateTime             = NSDate().timeIntervalSince1970
        let charsInIntervalCount = sizeof(NSTimeInterval) / sizeof(CUnsignedChar)
        var dateTimeChars        = Array<CUnsignedChar>(count: charsInIntervalCount, repeatedValue: 0)
        
        memcpy(&dateTimeChars, &dateTime, UInt(charsInIntervalCount))
        crypto_hash_sha512_update(&self.state, dateTimeChars, UInt64(sizeof(NSTimeInterval)))
    }
    
    private func addProccessIdToHash() {
        var processId      = NSProcessInfo().processIdentifier
        let charsInInt32   = sizeof(Int32) / sizeof(CUnsignedChar)
        var processIdChars = Array<CUnsignedChar>(count: charsInInt32, repeatedValue: 0)
        
        memcpy(&processIdChars, &processId, UInt(charsInInt32))
        crypto_hash_sha512_update(&self.state, processIdChars, UInt64(sizeof(Int32)))
    }
    
    private func addSystemUpTimeToHash() {
        var systemUpTime         = NSProcessInfo().systemUptime
        let charsInIntervalCount = sizeof(NSTimeInterval) / sizeof(CUnsignedChar)
        var upTimeChars          = Array<CUnsignedChar>(count: charsInIntervalCount, repeatedValue: 0)
        
        memcpy(&upTimeChars, &systemUpTime, UInt(charsInIntervalCount))
        crypto_hash_sha512_update(&self.state, upTimeChars, UInt64(sizeof(NSTimeInterval)))
    }
}
