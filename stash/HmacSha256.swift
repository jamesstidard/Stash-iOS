//
//  HmacSha256.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation


class HmacSha256 {
    
    class var HashBytes :Int { return Int(crypto_auth_hmacsha256_bytes()) }
    class var KeyBytes  :Int { return Int(crypto_auth_hmacsha256_keybytes()) }
    
    
    class func hash(_ message :Data, key :Data) -> Data?
    {
        if key.count == HashBytes {
            
            if var hash = NSMutableData(length: HashBytes) {
                
                let messagePtr = (message as NSData).bytes.bindMemory(to: UInt8.self, capacity: message.count)
                let keyPtr     = (key as NSData).bytes.bindMemory(to: UInt8.self, capacity: key.count)
                var hashPtr    = UnsafeMutablePointer<UInt8>(mutating: hash.bytes.bindMemory(to: UInt8.self, capacity: hash.count))
                
                if crypto_auth_hmacsha256(hashPtr, messagePtr, UInt64(message.count), keyPtr) == SodiumSuccess {
                    return hash as Data
                }
            }
        }
        
        return nil
    }
}
