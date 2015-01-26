//
//  EnScrypt.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation



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