//
//  SodiumWrapper.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

private var SodiumSuccess :Int32 { return 0 }


class Ed25519 {
    
    class var SeedBytes   :Int { return Int(crypto_sign_ed25519_seedbytes()) }
    class var SecretBytes :Int { return Int(crypto_sign_ed25519_secretkeybytes()) }
    class var PublicBytes :Int { return Int(crypto_sign_ed25519_publickeybytes()) }
    class var SignBytes   :Int { return Int(crypto_sign_bytes()) }
    
    
    class func keyPairFromSeed(let seed: NSData) -> (secretKey: NSData, publicKey: NSData)?
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

class sha512 {
    
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

class SodiumUtilities {
    
    class func initialiseSodium() {
        sodium_init()
    }
    
    class func randomBytes(length: Int) -> NSData?
    {
        if length > 0 {
            
            if var bytes = NSMutableData(length: length) {
                
                var bytesPtr = UnsafeMutablePointer<UInt8>(bytes.bytes)
                
                randombytes_buf(bytesPtr, UInt(length))
            }
        }
        
        return nil
    }
}

class Scrypt {
    
    class var MaxSaltBytes :Int { return Int(crypto_pwhash_scryptsalsa208sha256_saltbytes()) }
    
    
    class func salsa208Sha256(password: NSData?, salt: NSData?, N: UInt64, r: UInt32, p: UInt32) -> NSMutableData?
    {
        if salt?.length <= MaxSaltBytes
        {
            let passwordLength = password?.length ?? 0
            let saltLength     = salt?.length ?? 0
            
            if let out = NSMutableData(length: MaxSaltBytes) {
                
                var passwordPtr = (password != nil) ? UnsafeMutablePointer<UInt8>(password!.bytes) : nil
                var saltPtr     = (salt != nil)     ? UnsafeMutablePointer<UInt8>(salt!.bytes)     : nil
                var outPtr      = UnsafeMutablePointer<UInt8>(out.bytes)
                
                if crypto_pwhash_scryptsalsa208sha256_ll(passwordPtr, UInt(passwordLength), saltPtr, UInt(saltLength), N, r, p, outPtr, UInt(MaxSaltBytes)) == SodiumSuccess {
                    return out
                }
            }
        }
        
        return nil
    }
}

class EnScrypt {
    
    class func salsa208Sha256(password: NSData?, var salt: NSData?, N: UInt64, r: UInt32, p: UInt32, i: Int) -> NSData?
    {
        var finalOut: NSMutableData?
        var finalOutPtr: UnsafeMutablePointer<UInt8>?
        
        for x in 1...i {
            
            if let out = Scrypt.salsa208Sha256(password, salt: salt, N: N, r: r, p: p) {
                
                // set new salt as output of last Scrypt
                salt = out.mutableCopy() as? NSData
                
                // if first cycle then store initial out into final and get pointer
                if x == 1 {
                    finalOut    = out.mutableCopy() as? NSMutableData
                    finalOutPtr = UnsafeMutablePointer<UInt8>(finalOut!.bytes)
                }
                // else, XOR the out with the running finalOut and store back into out
                else {
                    var outPtr = UnsafeMutablePointer<UInt8>(out.bytes)
                    for byte in 0..<out.length {
                        finalOutPtr![byte] = finalOutPtr![byte] ^ outPtr[byte]
                    }
                }
            }
            else
            {
                return nil
            }
        }
        
        return finalOut
    }
}