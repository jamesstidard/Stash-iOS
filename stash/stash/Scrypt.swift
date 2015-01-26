//
//  Scrypt.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation


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