//
//  Sha512.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation


class Sha512 {
    
    typealias sha512State = crypto_hash_sha512_state
    
    class var HashBytes :Int { return Int(crypto_auth_hmacsha512_bytes()) }
    class var KeyBytes  :Int { return Int(crypto_auth_hmacsha512_keybytes()) }
    
    
    class func hash(message :NSData, key :NSData) -> NSData?
    {
        if key.length == HashBytes {
            
            if var hash = NSMutableData(length: HashBytes) {
                
                let messagePtr = UnsafePointer<UInt8>(message.bytes)
                let keyPtr     = UnsafePointer<UInt8>(key.bytes)
                var hashPtr    = UnsafeMutablePointer<UInt8>(hash.bytes)
                
                if crypto_auth_hmacsha512(hashPtr, messagePtr, UInt64(message.length), keyPtr) == SodiumSuccess {
                    return hash
                }
            }
        }
        
        return nil
    }
    
    class func openHash(inout state :sha512State)
    {
        crypto_hash_sha512_init(&state)
    }
    
    class func updateHash(inout state :sha512State, data :NSData)
    {
        let dataPtr = UnsafePointer<UInt8>(data.bytes)
        
        crypto_hash_sha512_update(&state, dataPtr, UInt64(data.length))
    }
    
    class func closeHash(inout state :sha512State) -> NSData?
    {
        if var hash = NSMutableData(length: HashBytes) {
            
            var hashPtr = UnsafeMutablePointer<UInt8>(hash.bytes)
            
            if crypto_hash_sha512_final(&state, hashPtr) == SodiumSuccess {
                return hash
            }
        }
        
        return nil
    }
}