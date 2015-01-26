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
    
    
    class func hash(message :NSData, key :NSData) -> NSData?
    {
        if key.length == HashBytes {
            
            if var hash = NSMutableData(length: HashBytes) {
                
                let messagePtr = UnsafePointer<UInt8>(message.bytes)
                let keyPtr     = UnsafePointer<UInt8>(key.bytes)
                var hashPtr    = UnsafeMutablePointer<UInt8>(hash.bytes)
                
                if crypto_auth_hmacsha256(hashPtr, messagePtr, UInt64(message.length), keyPtr) == SodiumSuccess {
                    return hash
                }
            }
        }
        
        return nil
    }
}