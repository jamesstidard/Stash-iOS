//
//  XORStorePasswordManagement.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension XORStore {
    
    func decryptCipherTextWithPassword(password: String) -> NSData?
    {
        return self.decryptCipherTextWithPassword(password, passwordEncoding: NSUTF8StringEncoding)
    }
    
    func decryptCipherTextWithPassword(password: String, passwordEncoding: NSStringEncoding) -> NSData?
    {
        if let passwordData = password.dataUsingEncoding(passwordEncoding, allowLossyConversion: false) {
            return self.decryptCipherTextWithPasswordData(passwordData)
        }
        return nil
    }
    
    func decryptCipherTextWithPasswordData(passwordData: NSData) -> NSData?
    {
        if let key = self.keyFromPassword(passwordData) where self.isValidKey(key)
        {
            if (self.identity.settings?.touchIDEnabled == true) {
                XORStore.updateKeychain(identityName: self.identity.name, key: key, insertIfNeeded: true)
            }
            
            return self.ciphertext ^ key
        }
        return nil
    }
    
    func decryptCipherText(
        touchIDPromptMessage prompt: String?,
        passwordRequiredCallback getPassword: (Void -> String)) -> NSData?
    {
        // try and get key from keychain
        if let
            prompt = prompt,
            key    = XORStore.getKeyFromKeychain(identityName: self.identity.name, authenticationPrompt: prompt)
        where
            self.isValidKey(key)
        {
            return self.ciphertext ^ key
        }
        
        // else get password from callback
        return decryptCipherTextWithPassword(getPassword())
    }
    
    // change password
    func changePassword(oldPassword: NSData, newPassword: NSData) -> Bool {
        // try decrypt under old password
        if let
            decryptedData = self.decryptCipherTextWithPasswordData(oldPassword),
            newKeyBundle  = XORStore.makeKeyFromPassword(newPassword)
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