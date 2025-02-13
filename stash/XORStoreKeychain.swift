//
//  XORStoreTouchID.swift
//  stash
//
//  Created by James Stidard on 17/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension XORStore
{
    func decryptCipherTextWithKeychain(#prompt: String) -> Data? {
        return XORStore.getKeyFromKeychain(identityName: self.identity.name, authenticationPrompt: prompt)
    }
    
    func removeFromKeychain() -> Bool {
        return XORStore.removeFromKeychain(identityName: self.identity.name)
    }
    
    internal class func addToKeychain(#identityName: String, _ key: Data) -> Bool
    {
        var error: Unmanaged<CFError>?
        let sac = SecAccessControlCreateWithFlags(
                    kCFAllocatorDefault,
                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                    .userPresence, &error).takeRetainedValue()
        
        if error != nil { return false }
        
        let insert = NSDictionary(
            objects: [kSecClassGenericPassword as! String, "Stash", identityName, key, sac],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String, kSecValueData as! String, kSecAttrAccessControl as! String]) as CFDictionaryRef
        
        return SecItemAdd(insert, nil) == errSecSuccess
    }
    
    internal class func removeFromKeychain(#identityName: String) -> Bool
    {
        let delete = NSDictionary(
            objects: [kSecClassGenericPassword as! String, "Stash", identityName],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String]) as CFDictionaryRef
        
        return SecItemDelete(delete) == errSecSuccess
    }
    
    internal class func updateKeychain(#identityName: String, _ key: Data, insertIfNeeded: Bool) -> Bool
    {
        let query = NSDictionary(
            objects: [kSecClassGenericPassword, "Stash", identityName],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String]) as CFDictionaryRef
        let update = NSDictionary(object: key, forKey: kSecValueData as String as NSCopying) as CFDictionary
        
        let result = SecItemUpdate(query, update)
        
        if result == errSecSuccess {
            return true
        }
        else if result == errSecItemNotFound && insertIfNeeded {
            return self.addToKeychain(identityName: identityName, key: key)
        } else {
            return false
        }
    }
    
    internal class func existsOnKeychain(#identityName: String) -> Bool
    {
        let query = NSDictionary(
            objects: [kSecClassGenericPassword, "Stash", identityName],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String]) as CFDictionaryRef
        return SecItemCopyMatching(query, nil) == errSecSuccess
    }
    
    internal class func getKeyFromKeychain(#identityName: String, authenticationPrompt prompt: String) -> Data?
    {
        let query = NSDictionary(
            objects: [kSecClassGenericPassword, "Stash", identityName, true, prompt],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String, kSecReturnData as! String, kSecUseOperationPrompt as! String]) as CFDictionaryRef
        
        var dataTypeRef: Unmanaged<CFTypeRef>?
        if  SecItemCopyMatching(query, &dataTypeRef) == errSecSuccess {
            if dataTypeRef != nil {
                return dataTypeRef!.takeRetainedValue() as? Data
            }
        }
        return nil
    }
}
