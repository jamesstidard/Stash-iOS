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
        
        if self.queue.suspended {
            return result
        }
        
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
