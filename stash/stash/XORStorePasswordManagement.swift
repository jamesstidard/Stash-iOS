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
        if let key = keyFromPassword(password) {
            if isValidKey(key) {
                return self.ciphertext ^ key
            }
        }
        return nil
    }
    
    class func makeKeyFromPassword(password: NSData) -> (key: NSData, salt: NSData, N: UInt64, i: Int, tag: NSData)? {
        let N = EnScryptDefaultNCost
        let r = EnScryptDefaultRCost
        let p = EnScryptDefaultParallelisation
        let i = EnScryptDefaultIterations
        
        if let salt = SodiumUtilities.randomBytes(32) {
            if let newKey = EnScrypt.salsa208Sha256(password, salt: salt, N: N, r: r, p: p, i: i) {
                if let tag = XORStore.verificationTagFromKey(newKey) {
                    return (newKey, salt, N, i, tag)
                }
            }
        }
        
        return nil
    }
    
    func keyFromPassword(password: NSData) -> NSData? {
        let i = self.scryptIterations
        let N = self.scryptMemoryFactor
        let r = Scrypt.rValueFrom(N)
        let p = EnScryptDefaultParallelisation
        
        if r == nil {
            return nil
        }
        
        return EnScrypt.salsa208Sha256(password, salt: self.scryptSalt, N: N, r: r!, p: p, i: i)
    }
    
    // change password
    func changePassword(oldPassword: NSData, newPassword: NSData) -> Bool {
        // try decrypt under old password
        if let decryptedData = self.decryptCipherTextWithPassword(oldPassword) {
            // create new key from password
            if let newKeyBundle = XORStore.makeKeyFromPassword(newPassword) {
                // encrypt and store new cipher data under new key and update properties of new key
                self.ciphertext         = decryptedData ^ newKeyBundle.key
                self.scryptIterations   = newKeyBundle.i
                self.scryptMemoryFactor = newKeyBundle.N
                self.scryptSalt         = newKeyBundle.salt
                self.verificationTag    = newKeyBundle.tag
                
                return true
            }
        }
        return false
    }
    
    // verify key
    func isValidKey(key: NSData) -> Bool {
        if let tag = XORStore.verificationTagFromKey(key) {
            return tag.isEqualToData(self.verificationTag)
        }
        return false
    }
    
    // varification tag for key
    class func verificationTagFromKey(key: NSData) -> NSData? {
        let VerificationBytes = 16
        return Sha256.hash(key)?.subdataWithRange(NSRange(location: 0, length: VerificationBytes))
    }
}