//
//  SecureStoreAbstract.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension SecureStore {
    
    class func makeKeyFromPassword(_ password: Data) -> (key: Data, salt: Data, N: UInt64, i: Int, tag: Data)?
    {
        return self.makeKeyFromPassword(password, storageType: .export)
    }
    
    class func makeKeyFromPassword(_ password: Data, storageType: EnScryptStorageType) -> (key: Data, salt: Data, N: UInt64, i: Int, tag: Data)?
    {
        let params = EnScryptParameters(type: storageType)
        return self.makeKeyFromPassword(password, enScriptParameters: params)
    }
    
    class func makeKeyFromPassword(_ password: Data, enScriptParameters params: EnScryptParameters) -> (key: Data, salt: Data, N: UInt64, i: Int, tag: Data)?
    {
        let (N, r, p, i) = (params.N, params.r, params.p, params.i)
        
        if let
            salt   = SodiumUtilities.randomBytes(32),
            let newKey = EnScrypt.salsa208Sha256(password, salt: salt, N: N, r: r, p: p, i: i),
            let tag    = XORStore.verificationTagFromKey(newKey)
        {
            return (newKey, salt, N, i, tag)
        }
        
        return nil
    }
    
    internal func keyFromPassword(_ password: Data) -> Data? {
        let i = Int(self.scryptIterations)
        let N = UInt64(self.scryptMemoryFactor)
        let r = Scrypt.rValueFrom(N)
        let p = EnScryptDefaultParallelisation
        
        if r == nil { return nil }
        
        return EnScrypt.salsa208Sha256(password, salt: self.scryptSalt, N: N, r: r!, p: p, i: i)
    }
    
    // verify key
    internal func isValidKey(_ key: Data) -> Bool {
        if let tag = XORStore.verificationTagFromKey(key) {
            return (tag == self.verificationTag as Data)
        }
        return false
    }
    
    // varification tag for key
    internal class func verificationTagFromKey(_ key: Data) -> Data? {
        let VerificationBytes = 16
        return Sha256.hash(key)?.subdata(with: NSRange(location: 0, length: VerificationBytes))
    }
}
