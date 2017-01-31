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
    
    
    class func keyPairFromSeed(_ seed: Data) -> (secretKey: Data, publicKey: Data)?
    {
        if let
            secretKey = NSMutableData(length: SecretBytes),
            let publicKey = NSMutableData(length: PublicBytes),
            seed.count == SeedBytes
        {
            let seedPtr      = (seed as NSData).bytes.bindMemory(to: UInt8.self, capacity: seed.count)
            var secretKeyPtr = UnsafeMutablePointer<UInt8>(secretKey.mutableBytes)
            var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
            
            if crypto_sign_ed25519_seed_keypair(publicKeyPtr, secretKeyPtr, seedPtr) == SodiumSuccess {
                return (secretKey: secretKey as Data, publicKey: publicKey as Data)
            }
        }
        
        return nil
    }
    
    class func keyPair() -> (secretKey: Data, publicKey: Data)?
    {
        if let
            secretKey = NSMutableData(length: SecretBytes),
            let publicKey = NSMutableData(length: PublicBytes)
        {
            var secretKeyPtr = UnsafeMutablePointer<UInt8>(secretKey.mutableBytes)
            var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
            
            if crypto_sign_ed25519_keypair(publicKeyPtr, secretKeyPtr) == SodiumSuccess {
                return (secretKey: secretKey as Data, publicKey: publicKey as Data)
            }
        }
        
        return nil
    }
    
    class func makePublicKey(_ secretKey: Data) -> Data?
    {
        if let
            publicKey = NSMutableData(length: PublicBytes),
            secretKey.count == SecretBytes
        {
            var secretKeyPtr = (secretKey as NSData).bytes.bindMemory(to: UInt8.self, capacity: secretKey.count)
            var publicKeyPtr = UnsafeMutablePointer<UInt8>(publicKey.mutableBytes)
            
            if crypto_sign_ed25519_sk_to_pk(publicKeyPtr, secretKeyPtr) == SodiumSuccess {
                return publicKey as Data
            }
        }
        
        return nil
    }
    
    class func signatureForMessage(_ message :Data, secretKey: Data) -> Data?
    {
        if var
            signature = NSMutableData(length: SignBytes),
            secretKey.count == SecretBytes
        {
            
            let messagePtr   = (message as NSData).bytes.bindMemory(to: UInt8.self, capacity: message.count)
            var secretKeyPtr = (secretKey as NSData).bytes.bindMemory(to: UInt8.self, capacity: secretKey.count)
            var signaturePtr = UnsafeMutablePointer<UInt8>(mutating: signature.bytes.bindMemory(to: UInt8.self, capacity: signature.count))
            
            if crypto_sign_detached(signaturePtr, nil, messagePtr, UInt64(message.count), secretKeyPtr) == SodiumSuccess {
                return signature as Data
            }
        }
        
        return nil
    }
    
    class func diffieHellmanSharedSecret(secretKey edSecretKey: Data, publicKey edPublicKey: Data) -> Data?
    {
        var edSecretKey = edSecretKey, edPublicKey = edPublicKey
        // need to convert ED25519 keys to Curve25519 keys
        if let
            curveSecretKey = NSMutableData(length: Int(crypto_scalarmult_curve25519_bytes())),
            let curvePublicKey = NSMutableData(length: Int(crypto_scalarmult_curve25519_bytes())),
            let sharedSecret   = NSMutableData(length: Int(crypto_scalarmult_bytes())),
            edSecretKey.count == SecretBytes && edPublicKey.count == PublicBytes
        {
            var edSecretKeyPtr    = UnsafeMutablePointer<UInt8>(mutating: (edSecretKey as NSData).bytes.bindMemory(to: UInt8.self, capacity: edSecretKey.count))
            var edPublicKeyPtr    = UnsafeMutablePointer<UInt8>(mutating: (edPublicKey as NSData).bytes.bindMemory(to: UInt8.self, capacity: edPublicKey.count))
            var curveSecretKeyPtr = UnsafeMutablePointer<UInt8>(mutating: curveSecretKey.bytes.bindMemory(to: UInt8.self, capacity: curveSecretKey.count))
            var curvePublicKeyPtr = UnsafeMutablePointer<UInt8>(mutating: curvePublicKey.bytes.bindMemory(to: UInt8.self, capacity: curvePublicKey.count))
            var sharedSecretPtr   = UnsafeMutablePointer<UInt8>(mutating: sharedSecret.bytes.bindMemory(to: UInt8.self, capacity: sharedSecret.count))
            
            if  crypto_sign_ed25519_sk_to_curve25519(curveSecretKeyPtr, edSecretKeyPtr) == SodiumSuccess &&
                crypto_sign_ed25519_pk_to_curve25519(curvePublicKeyPtr, edPublicKeyPtr) == SodiumSuccess &&
                curveSecretKey.length == crypto_scalarmult_scalarbytes() &&
                curvePublicKey.length == crypto_scalarmult_scalarbytes() &&
                crypto_scalarmult(sharedSecretPtr, curveSecretKeyPtr, curvePublicKeyPtr) == SodiumSuccess
            {
                return sharedSecret as Data
            }
        }
        
        return nil
    }
}
