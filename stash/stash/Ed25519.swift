//
//  Ed25519.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation



class Ed25519 {
    
    class var SeedBytes     :Int { return Int(crypto_sign_ed25519_seedbytes()) }
    class var SecretBytes   :Int { return Int(crypto_sign_ed25519_secretkeybytes()) }
    class var PublicBytes   :Int { return Int(crypto_sign_ed25519_publickeybytes()) }
    class var SignBytes     :Int { return Int(crypto_sign_bytes()) }
    
    
    class func keyPairFromSeed(let seed: NSData) -> (secretKey: NSData, publicKey: NSData)?
    {
        if let
            secretKey = NSMutableData(length: SecretBytes),
            publicKey = NSMutableData(length: PublicBytes)
        where
            seed.length == SeedBytes
        {
            let seedPtr      = UnsafePointer<UInt8>(seed.bytes)
            var secretKeyPtr = UnsafeMutablePointer<UInt8>(secretKey.mutableBytes)
            var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
            
            if crypto_sign_ed25519_seed_keypair(publicKeyPtr, secretKeyPtr, seedPtr) == SodiumSuccess {
                return (secretKey: secretKey, publicKey: publicKey)
            }
        }
        
        return nil
    }
    
    class func keyPair() -> (secretKey: NSData, publicKey: NSData)?
    {
        if let
            secretKey = NSMutableData(length: SecretBytes),
            publicKey = NSMutableData(length: PublicBytes)
        {
            var secretKeyPtr = UnsafeMutablePointer<UInt8>(secretKey.mutableBytes)
            var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
            
            if crypto_sign_ed25519_keypair(publicKeyPtr, secretKeyPtr) == SodiumSuccess {
                return (secretKey: secretKey, publicKey: publicKey)
            }
        }
        
        return nil
    }
    
    class func makePublicKey(let secretKey: NSData) -> NSData?
    {
        if let
            publicKey = NSMutableData(length: PublicBytes)
        where
            secretKey.length == SecretBytes
        {
            var secretKeyPtr = UnsafePointer<UInt8>(secretKey.bytes)
            var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
            
            if crypto_sign_ed25519_sk_to_pk(publicKeyPtr, secretKeyPtr) == SodiumSuccess {
                return publicKey
            }
        }
        
        return nil
    }
    
    class func signatureForMessage(message :NSData, secretKey: NSData) -> NSData?
    {
        if var
            signature = NSMutableData(length: SignBytes)
        where
            secretKey.length == SecretBytes
        {
            
            let messagePtr   = UnsafePointer<UInt8>(message.bytes)
            var secretKeyPtr = UnsafePointer<UInt8>(secretKey.bytes)
            var signaturePtr = UnsafeMutablePointer<UInt8>(signature.bytes)
            
            if crypto_sign_detached(signaturePtr, nil, messagePtr, UInt64(message.length), secretKeyPtr) == SodiumSuccess {
                return signature
            }
        }
        
        return nil
    }
    
    class func diffieHellmanSharedSecret(var secretKey edSecretKey: NSData, var publicKey edPublicKey: NSData) -> NSData?
    {
        // need to convert ED25519 keys to Curve25519 keys
        if let
            curveSecretKey = NSMutableData(length: Int(crypto_scalarmult_curve25519_bytes())),
            curvePublicKey = NSMutableData(length: Int(crypto_scalarmult_curve25519_bytes())),
            sharedSecret   = NSMutableData(length: Int(crypto_scalarmult_bytes()))
        where
            edSecretKey.length == SecretBytes && edPublicKey.length == PublicBytes
        {
            var edSecretKeyPtr    = UnsafeMutablePointer<UInt8>(edSecretKey.bytes)
            var edPublicKeyPtr    = UnsafeMutablePointer<UInt8>(edPublicKey.bytes)
            var curveSecretKeyPtr = UnsafeMutablePointer<UInt8>(curveSecretKey.bytes)
            var curvePublicKeyPtr = UnsafeMutablePointer<UInt8>(curvePublicKey.bytes)
            var sharedSecretPtr   = UnsafeMutablePointer<UInt8>(sharedSecret.bytes)
            
            if  crypto_sign_ed25519_sk_to_curve25519(curveSecretKeyPtr, edSecretKeyPtr) == SodiumSuccess &&
                crypto_sign_ed25519_pk_to_curve25519(curvePublicKeyPtr, edPublicKeyPtr) == SodiumSuccess &&
                curveSecretKey.length == crypto_scalarmult_scalarbytes() &&
                curvePublicKey.length == crypto_scalarmult_scalarbytes() &&
                crypto_scalarmult(sharedSecretPtr, curveSecretKeyPtr, curvePublicKeyPtr) == SodiumSuccess
            {
                return sharedSecret
            }
        }
        
        return nil
    }
}
