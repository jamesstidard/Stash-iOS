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
    
    
    class func hash(var message :NSData) -> NSData?
    {
        if var hash = NSMutableData(length: HashBytes) {
                
            let messagePtr = UnsafePointer<UInt8>(message.bytes)
            var hashPtr    = UnsafeMutablePointer<UInt8>(hash.bytes)
                
            if crypto_hash_sha256(hashPtr, messagePtr, UInt64(message.length)) == SodiumSuccess {
                return hash
            }
        }
        
        return nil
    }
}

