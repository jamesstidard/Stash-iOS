//
//  XORStorePasswordManagement.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension XORStore {
    
    func decryptCipherTextWithPassword(password: NSData) -> NSData?
    {
        let i = self.scryptIterations
        let N = self.scryptMemoryFactor
        let r = Scrypt.rValueFrom(N)
        let p = EnScryptDefaultParallelisation
        
        // TODO: Enable in swift v1.2
//        if let
//            i = self.scryptIterations,
//            N = self.scryptMemoryFactor
//            r = Scrypt.rValueFrom(N)
//            p = EnScryptDefaultParallelisation {
//            
//        }
        
        if r == nil {
            return nil
        }
        
//        if let
//            key = EnScrypt.salsa208Sha256(password, salt: self.scryptSalt, N: N, r: r!, p: p, i: i),
//            tag = XORStore.verificationTagFromKey(key)
//            where tag == self.verificationTag {
//            
//            
//        }
        
        
        
        
        return nil
    }
    
    // change password
    
    // verify password
    
    // varification tag for key
    class func verificationTagFromKey(key: NSData) -> NSData? {
        let VerificationBytes = 16
        return Sha256.hash(key)?.subdataWithRange(NSRange(location: 0, length: VerificationBytes))
    }
}