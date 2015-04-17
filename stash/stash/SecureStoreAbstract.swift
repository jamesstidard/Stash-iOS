//
//  SecureStoreAbstract.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension SecureStore {
    
    class func makeKeyFromPassword(password: NSData) -> (key: NSData, salt: NSData, N: UInt64, i: Int, tag: NSData)?
    {
        return self.makeKeyFromPassword(password, storageType: .Export)
    }
    
    class func makeKeyFromPassword(password: NSData, storageType: EnScryptStorageType) -> (key: NSData, salt: NSData, N: UInt64, i: Int, tag: NSData)?
    {
        let params = EnScryptParameters(type: storageType)
        return self.makeKeyFromPassword(password, enScriptParameters: params)
    }
    
    class func makeKeyFromPassword(password: NSData, enScriptParameters params: EnScryptParameters) -> (key: NSData, salt: NSData, N: UInt64, i: Int, tag: NSData)?
    {
        let (N, r, p, i) = (params.N, params.r, params.p, params.i)
        
        if let
            salt   = SodiumUtilities.randomBytes(32),
            newKey = EnScrypt.salsa208Sha256(password, salt: salt, N: N, r: r, p: p, i: i),
            tag    = XORStore.verificationTagFromKey(newKey)
        {
            return (newKey, salt, N, i, tag)
        }
        
        return nil
    }
    
    internal func keyFromPassword(password: NSData) -> NSData? {
        let i = Int(self.scryptIterations)
        let N = UInt64(self.scryptMemoryFactor)
        let r = Scrypt.rValueFrom(N)
        let p = EnScryptDefaultParallelisation
        
        if r == nil { return nil }
        
        return EnScrypt.salsa208Sha256(password, salt: self.scryptSalt, N: N, r: r!, p: p, i: i)
    }
    
    // verify key
    internal func isValidKey(key: NSData) -> Bool {
        if let tag = XORStore.verificationTagFromKey(key) {
            return tag.isEqualToData(self.verificationTag)
        }
        return false
    }
    
    // varification tag for key
    internal class func verificationTagFromKey(key: NSData) -> NSData? {
        let VerificationBytes = 16
        return Sha256.hash(key)?.subdataWithRange(NSRange(location: 0, length: VerificationBytes))
    }
}