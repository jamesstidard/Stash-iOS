//
//  EntropyMachine.swift
//  stash
//
//  Created by James Stidard on 06/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation


class EntropyMachine {
    
    private var started :Bool = false
    private var state   :crypto_hash_sha512_state = crypto_hash_sha512_state(
        state: (0, 0, 0, 0, 0, 0, 0, 0),
        count: (0, 0),
        buf:   (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0))
    private var result :NSData? = nil
    
    func start() {
        // start the hash function (if not already started)
        if !started {
            // switch hash state to on
            started = true
            result  = nil
            
            // start hash function
            crypto_hash_sha512_init(&state)
            
            
            // Input initial entropy
            // I) random bytes from libsodium
            let charsCount = Int(crypto_hash_sha512_BYTES) / sizeof(CUnsignedChar) // number of chars in sha512
            var random     = UnsafeMutablePointer<CUnsignedChar>.alloc(charsCount)

            randombytes_buf(random, UInt(crypto_hash_sha512_BYTES))
            crypto_hash_sha512_update(&state, random, UInt64(crypto_hash_sha512_BYTES))
            random.dealloc(charsCount)
            
            
            // II) System timeDate
            var dateTime = NSDate().timeIntervalSince1970
            let charsInIntervalCount = sizeof(NSTimeInterval) / sizeof(CUnsignedChar)
            var dateTimeChars = Array<CUnsignedChar>(count: charsInIntervalCount, repeatedValue: 0)
            
            memcpy(&dateTimeChars, &dateTime, UInt(charsInIntervalCount))
            crypto_hash_sha512_update(&state, dateTimeChars, UInt64(sizeof(NSTimeInterval)))
            
            
            // III) Process Info
            var processId = NSProcessInfo().processIdentifier
            let charsInInt32 = sizeof(Int32) / sizeof(CUnsignedChar)
            var processIdChars = Array<CUnsignedChar>(count: charsInInt32, repeatedValue: 0)
            
            memcpy(&processIdChars, &processId, UInt(charsInInt32))
            crypto_hash_sha512_update(&state, processIdChars, UInt64(sizeof(Int32)))
            
            
            // IV) System up time
            var systemUpTime = NSProcessInfo().systemUptime
            var upTimeChars = Array<CUnsignedChar>(count: charsInIntervalCount, repeatedValue: 0)
            
            memcpy(&upTimeChars, &systemUpTime, UInt(charsInIntervalCount))
            crypto_hash_sha512_update(&state, upTimeChars, UInt64(sizeof(NSTimeInterval)))
        }
    }
    
    func addEntropy(entropy: NSData) {
        if started {
            var entropyChars = UnsafePointer<CUnsignedChar>(entropy.bytes)
            crypto_hash_sha512_update(&state, entropyChars, UInt64(entropy.length))
        }
    }
    
    func stop() -> NSData? {
        
        if started {
            let charsCount = Int(crypto_hash_sha512_BYTES) / sizeof(CUnsignedChar)// number of chars in sha512
            var hash       = UnsafeMutablePointer<CUnsignedChar>.alloc(charsCount)
            
            crypto_hash_sha512_final(&state, hash)
            
            result = NSData(bytes: hash, length: Int(crypto_hash_sha512_BYTES))
            
            started = false
        }
        
        return result
    }
}
