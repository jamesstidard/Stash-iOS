//
//  Ed25519.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation



class Ed25519 {
    
    class var SeedBytes   :Int { return Int(crypto_sign_ed25519_seedbytes()) }
    class var SecretBytes :Int { return Int(crypto_sign_ed25519_secretkeybytes()) }
    class var PublicBytes :Int { return Int(crypto_sign_ed25519_publickeybytes()) }
    class var SignBytes   :Int { return Int(crypto_sign_bytes()) }
    
    
    class func keyPairFromSeed(let seed: NSData) -> (secretKey: NSData?, publicKey: NSData)?
    {
        // Check seed is correct length
        if seed.length == SeedBytes {
            
            // create keys
            if let secretKey     = NSMutableData(length: SecretBytes) {
                if let publicKey = NSMutableData(length: PublicBytes) {
                    
                    let seedPtr      = UnsafePointer<UInt8>(seed.bytes)
                    var secretKeyPtr = UnsafeMutablePointer<UInt8>(secretKey.mutableBytes)
                    var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
                    
                    if crypto_sign_ed25519_seed_keypair(publicKeyPtr, secretKeyPtr, seedPtr) == SodiumSuccess {
                        return (secretKey: secretKey, publicKey: publicKey);
                    }
                }
            }
        }
        
        return nil
    }
    
    class func signatureForMessage(message :NSData, secretKey: NSData) -> NSData?
    {
        if secretKey.length == SecretBytes {
            
            if var signature = NSMutableData(length: SignBytes) {
                
                let messagePtr   = UnsafePointer<UInt8>(message.bytes)
                var secretKeyPtr = UnsafePointer<UInt8>(secretKey.bytes)
                var signaturePtr = UnsafeMutablePointer<UInt8>(signature.bytes)
                
                if crypto_sign_detached(signaturePtr, nil, messagePtr, UInt64(message.length), secretKeyPtr) == SodiumSuccess {
                    return signature
                }
            }
        }
        
        return nil
    }
}
