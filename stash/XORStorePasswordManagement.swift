//
//  XORStorePasswordManagement.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension XORStore {
    
    func decryptCipherTextWithPassword(_ password: String) -> Data?
    {
        return self.decryptCipherTextWithPassword(password, passwordEncoding: String.Encoding.utf8)
    }
    
    func decryptCipherTextWithPassword(_ password: String, passwordEncoding: String.Encoding) -> Data?
    {
        if let passwordData = password.data(using: passwordEncoding, allowLossyConversion: false) {
            return self.decryptCipherTextWithPasswordData(passwordData)
        }
        return nil
    }
    
    func decryptCipherTextWithPasswordData(_ passwordData: Data) -> Data?
    {
        if let key = self.keyFromPassword(passwordData), self.isValidKey(key)
        {
            if (self.identity.settings?.touchIDEnabled == true) {
                XORStore.updateKeychain(identityName: self.identity.name, key: key, insertIfNeeded: true)
            }
            
            return self.ciphertext ^ key
        }
        return nil
    }
    
    // change password
    func changePassword(_ oldPassword: Data, newPassword: Data) -> Bool {
        // try decrypt under old password
        if let
            decryptedData = self.decryptCipherTextWithPasswordData(oldPassword),
            let newKeyBundle  = XORStore.makeKeyFromPassword(newPassword)
        {
            if (self.identity.settings?.touchIDEnabled == true) {
                XORStore.updateKeychain(identityName: self.identity.name, key: newKeyBundle.key, insertIfNeeded: true)
            }
            
            // encrypt and store new cipher data under new key and update properties of new key
            self.ciphertext         = decryptedData ^ newKeyBundle.key
            self.scryptIterations   = Int64(newKeyBundle.i)
            self.scryptMemoryFactor = Int64(newKeyBundle.N)
            self.scryptSalt         = newKeyBundle.salt
            self.verificationTag    = newKeyBundle.tag
                
            return true
        }
        return false
    }
}
