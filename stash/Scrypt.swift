//
//  Scrypt.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}



class Scrypt {
    
    class var MaxSaltBytes :Int { return Int(crypto_pwhash_scryptsalsa208sha256_saltbytes()) }
    
    
    class func salsa208Sha256(_ password: Data?, salt: Data?, N: UInt64, r: UInt32, p: UInt32) -> NSMutableData?
    {
        if salt?.count <= MaxSaltBytes
        {
            let passwordLength = password?.count ?? 0
            let saltLength     = salt?.count ?? 0
            
            if let out = NSMutableData(length: MaxSaltBytes) {
                
                var passwordPtr = (password != nil) ? UnsafeMutablePointer<UInt8>(mutating: (password! as NSData).bytes.bindMemory(to: UInt8.self, capacity: password!.count)) : nil
                var saltPtr     = (salt != nil)     ? UnsafeMutablePointer<UInt8>(mutating: (salt! as NSData).bytes.bindMemory(to: UInt8.self, capacity: salt!.count))     : nil
                var outPtr      = UnsafeMutablePointer<UInt8>(mutating: out.bytes.bindMemory(to: UInt8.self, capacity: out.count))
                
                if crypto_pwhash_scryptsalsa208sha256_ll(passwordPtr, Int(passwordLength), saltPtr, Int(saltLength), N, r, p, outPtr, Int(MaxSaltBytes)) == SodiumSuccess {
                    return out
                }
            }
        }
        
        return nil
    }
    
    class func rValueFrom(_ N: UInt64) -> UInt32? {
        // N needs to be of power 2
        if (N%2==0 && N>1) {
            return UInt32(N*2/(256/64))
        }
        return nil
    }
}
