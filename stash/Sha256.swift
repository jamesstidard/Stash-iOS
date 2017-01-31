//
//  Sha256.swift
//  stash
//
//  Created by James Stidard on 09/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

class Sha256 {
    
    class var HashBytes :Int { return Int(crypto_hash_sha256_bytes()) }
    
    
    class func hash(_ message :Data) -> Data?
    {
        var message = message
        if var hash = NSMutableData(length: HashBytes) {
                
            let messagePtr = (message as NSData).bytes.bindMemory(to: UInt8.self, capacity: message.count)
            var hashPtr    = UnsafeMutablePointer<UInt8>(mutating: hash.bytes.bindMemory(to: UInt8.self, capacity: hash.count))
                
            if crypto_hash_sha256(hashPtr, messagePtr, UInt64(message.count)) == SodiumSuccess {
                return hash as Data
            }
        }
        
        return nil
    }
}

