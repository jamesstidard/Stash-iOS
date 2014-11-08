//
//  EntropyMachine.swift
//  stash
//
//  Created by James Stidard on 06/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation


class EntropyMachine {
    
    // Holds the state of the open hash function
    private var state   :crypto_hash_sha512_state = crypto_hash_sha512_state(
        state: (0, 0, 0, 0, 0, 0, 0, 0),
        count: (0, 0),
        buf:   (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0)
    )
    // Serial queue to enforce thread safe execution when called from multiple threads
    private lazy var queue :NSOperationQueue = {
        var newQueue              = NSOperationQueue()
        newQueue.name             = "Entropy Machine Queue"
        newQueue.qualityOfService = .UserInitiated
        newQueue.maxConcurrentOperationCount = 1 // Serial queue
        return newQueue
        }()
    
    private var started :Bool    = false // Holds state of entropy machine
    

    
    func start() {
        
        self.queue.cancelAllOperations()
        self.queue.addOperationWithBlock { () -> Void in
            // start the hash function (if not already started)
            if !self.started {
                // switch hash state to on
                self.started = true
                
                // start hash function
                crypto_hash_sha512_init(&self.state)
                
                
                // Input initial entropy
                // I) random bytes from libsodium
                let charsCount = Int(crypto_hash_sha512_BYTES) / sizeof(CUnsignedChar) // number of chars in sha512
                var random     = UnsafeMutablePointer<CUnsignedChar>.alloc(charsCount)
                
                randombytes_buf(random, UInt(crypto_hash_sha512_BYTES))
                crypto_hash_sha512_update(&self.state, random, UInt64(crypto_hash_sha512_BYTES))
                random.dealloc(charsCount)
                
                
                // II) System timeDate
                var dateTime = NSDate().timeIntervalSince1970
                let charsInIntervalCount = sizeof(NSTimeInterval) / sizeof(CUnsignedChar)
                var dateTimeChars = Array<CUnsignedChar>(count: charsInIntervalCount, repeatedValue: 0)
                
                memcpy(&dateTimeChars, &dateTime, UInt(charsInIntervalCount))
                crypto_hash_sha512_update(&self.state, dateTimeChars, UInt64(sizeof(NSTimeInterval)))
                
                
                // III) Process Info
                var processId = NSProcessInfo().processIdentifier
                let charsInInt32 = sizeof(Int32) / sizeof(CUnsignedChar)
                var processIdChars = Array<CUnsignedChar>(count: charsInInt32, repeatedValue: 0)
                
                memcpy(&processIdChars, &processId, UInt(charsInInt32))
                crypto_hash_sha512_update(&self.state, processIdChars, UInt64(sizeof(Int32)))
                
                
                // IV) System up time
                var systemUpTime = NSProcessInfo().systemUptime
                var upTimeChars = Array<CUnsignedChar>(count: charsInIntervalCount, repeatedValue: 0)
                
                memcpy(&upTimeChars, &systemUpTime, UInt(charsInIntervalCount))
                crypto_hash_sha512_update(&self.state, upTimeChars, UInt64(sizeof(NSTimeInterval)))
            }

        }
    }
    
    func addEntropy(entropy: NSData) {
        
        self.queue.addOperationWithBlock { () -> Void in
            
            if self.started {
                var entropyChars = UnsafePointer<CUnsignedChar>(entropy.bytes)
                crypto_hash_sha512_update(&self.state, entropyChars, UInt64(entropy.length))
            }
        }
    }
    
    func stop() -> NSData? {
        
        var result :NSData?
        
        let block = NSBlockOperation { () -> Void in
            if self.started {
                let charsCount = Int(crypto_hash_sha512_BYTES) / sizeof(CUnsignedChar)// number of chars in sha512
                var hash       = UnsafeMutablePointer<CUnsignedChar>.alloc(charsCount)
                
                crypto_hash_sha512_final(&self.state, hash)
                
                result       = NSData(bytes: hash, length: Int(crypto_hash_sha512_BYTES))
                self.started = false
            }
        }
        block.qualityOfService = .UserInitiated
        block.queuePriority    = .VeryHigh
        
        self.queue.cancelAllOperations()
        self.queue.addOperations([block], waitUntilFinished: true)
        
        return result
    }
}
