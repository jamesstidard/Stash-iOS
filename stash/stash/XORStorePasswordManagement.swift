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
    
    
}