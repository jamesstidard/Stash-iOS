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
    
    
    class func hash(_ message :Data, key :Data) -> Data?
    {
        if key.count == HashBytes {
            
            if var hash = NSMutableData(length: HashBytes) {
                
                let messagePtr = (message as NSData).bytes.bindMemory(to: UInt8.self, capacity: message.count)
                let keyPtr     = (key as NSData).bytes.bindMemory(to: UInt8.self, capacity: key.count)
                var hashPtr    = UnsafeMutablePointer<UInt8>(mutating: hash.bytes.bindMemory(to: UInt8.self, capacity: hash.count))
                
                if crypto_auth_hmacsha512(hashPtr, messagePtr, UInt64(message.count), keyPtr) == SodiumSuccess {
                    return hash as Data
                }
            }
        }
        
        return nil
    }
    
    class func openHash(_ state :inout sha512State)
    {
        crypto_hash_sha512_init(&state)
    }
    
    class func updateHash(_ state :inout sha512State, data :Data)
    {
        let dataPtr = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
        
        crypto_hash_sha512_update(&state, dataPtr, UInt64(data.count))
    }
    
    class func closeHash(_ state :inout sha512State) -> Data?
    {
        if var hash = NSMutableData(length: HashBytes) {
            
            var hashPtr = UnsafeMutablePointer<UInt8>(mutating: hash.bytes.bindMemory(to: UInt8.self, capacity: hash.count))
            
            if crypto_hash_sha512_final(&state, hashPtr) == SodiumSuccess {
                return hash as Data
            }
        }
        
        return nil
    }
}
