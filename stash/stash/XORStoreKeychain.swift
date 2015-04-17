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
    internal class func enableTouchID(identityName: String, key: NSData) -> Bool
    {
        var error: Unmanaged<CFError>?
        let sac = SecAccessControlCreateWithFlags(
                    kCFAllocatorDefault,
                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                    .UserPresence, &error).takeRetainedValue()
        
        if error != nil { return false }
        
        let insert = NSDictionary(
            objects: [kSecClassGenericPassword as! String, "Stash", identityName, key, sac],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String, kSecValueData as! String, kSecAttrAccessControl as! String]) as CFDictionaryRef
        
        return SecItemAdd(insert, nil) == errSecSuccess
    }
    
    internal class func disableTouchID(identityName: String) -> Bool
    {
        let delete = NSDictionary(
            objects: [kSecClassGenericPassword as! String, "Stash", identityName],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String]) as CFDictionaryRef
        
        return SecItemDelete(delete) == errSecSuccess
    }
    
    internal class func updateTouchID(identityName: String, key: NSData) -> Bool
    {
        let query = NSDictionary(
            objects: [kSecClassGenericPassword, "Stash", identityName],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String]) as CFDictionaryRef
        let update = NSDictionary(object: key, forKey: kSecValueData as! String) as CFDictionaryRef
        
        return SecItemUpdate(query, update) == errSecSuccess
    }
    
    internal class func getKeyFromTouchID(identityName: String, authenticationPrompt prompt: String) -> NSData?
    {
        let query = NSDictionary(
            objects: [kSecClassGenericPassword, "Stash", identityName, true, prompt],
            forKeys: [kSecClass as! String, kSecAttrService as! String, kSecAttrAccount as! String, kSecReturnData as! String, kSecUseOperationPrompt as! String]) as CFDictionaryRef
        
        var dataTypeRef: Unmanaged<CFTypeRef>?
        if  SecItemCopyMatching(query, &dataTypeRef) == errSecSuccess && dataTypeRef != nil
        {
            return dataTypeRef!.takeRetainedValue() as? NSData
        }
        return nil
    }
}