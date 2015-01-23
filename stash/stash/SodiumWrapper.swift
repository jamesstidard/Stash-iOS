//
//  SodiumWrapper.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation


class SodiumWrapper {
    
    private class var SodiumSuccess :Int32 { return 0 }
    
    class var Ed25519SeedBytes   :Int { return Int(crypto_sign_ed25519_seedbytes()) }
    class var Ed25519SecretBytes :Int { return Int(crypto_sign_ed25519_secretkeybytes()) }
    class var Ed25519PublicBytes :Int { return Int(crypto_sign_ed25519_publickeybytes()) }
    
    
    class func ed25519KeyPairFromSeed(let seed: NSData) -> (secretKey: NSData, publicKey: NSData)?
    {
        // Check seed is correct length
        if seed.length == Ed25519SeedBytes {
            
            // create keys
            if let secretKey     = NSMutableData(length: Ed25519SecretBytes) {
                if let publicKey = NSMutableData(length: Ed25519PublicBytes) {
                    
                    let seedPtr      = UnsafePointer<UInt8>(seed.bytes)
                    var secretKeyPtr = UnsafeMutablePointer<UInt8>(secretKey.mutableBytes)
                    var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
                    
                    if crypto_sign_ed25519_seed_keypair(publicKeyPtr, secretKeyPtr, seedPtr) == SodiumSuccess {
                        return (secretKey: secretKey, publicKey: publicKey);
                    }
                }
            }
        }
        
        return nil;
    }
}