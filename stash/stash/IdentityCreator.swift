//
//  IdentityCreator.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

let IdentityClassNameKey    = "Identity"
let IdentityPropertyNameKey = "name"

extension Identity
{
    class func createIdentity(let name: String, inout password: String, inout seed: NSData, let context: NSManagedObjectContext) -> (identity: Identity, rescueCode: String)?
    {
        if seed.length != 64 {
            return nil
        }
        
        // Use the first 256-bits (32bytes) for seeding the identity lock and unlock keypair
        let identitySeed     = seed.subdataWithRange(NSRange(location: 0, length: 32))
        let rescueCodeSeed   = seed.subdataWithRange(NSRange(location: 32, length: 32))
        let rescueCodeBundle = Identity.rescueCodeBundleFromSeed(rescueCodeSeed)
        let passwordData     = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        if rescueCodeBundle == nil || passwordData == nil {
            return nil
        }
        
        if let (var unlockKey, var lockKey) = Ed25519.keyPairFromSeed(identitySeed) {
            var optionalUnlockKey: NSData? = unlockKey // needed to satify CGMStore inout
            
            var masterKey = EnHash.sha256(optionalUnlockKey!, iterations: 16)
            
            if masterKey == nil {
                return nil
            }
            
            // Send both keys off to generate on different thread
            var securedUnlockKey: GCMStore?
            var securedMasterKey: XORStore?
            
            let threadGroup = dispatch_group_create()
            dispatch_group_enter(threadGroup)
            dispatch_group_enter(threadGroup)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                securedUnlockKey = GCMStore.createGCMStore(&optionalUnlockKey, password: rescueCodeBundle!.data, context: context)
                dispatch_group_leave(threadGroup)
            })
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                securedMasterKey = XORStore.createXORStore(&masterKey!, password: passwordData!, storageType: .Local, context: context)
                dispatch_group_leave(threadGroup)
            })
        
            dispatch_group_wait(threadGroup, DISPATCH_TIME_FOREVER)
            
            if securedUnlockKey == nil || securedMasterKey == nil {
                return nil
            }
            
            unlockKey.secureMemZero()
            masterKey!.secureMemZero()
            identitySeed.secureMemZero()
            passwordData!.secureMemZero()
            rescueCodeSeed.secureMemZero()
            rescueCodeBundle!.data.secureMemZero()
            

            
            var bundle: (identity: Identity, rescueCode: String)?
            
            context.performBlockAndWait({
                // Check if Identity with same name exists
                let predicate        = NSPredicate(format: "%K == %@", argumentArray: [IdentityPropertyNameKey, name])
                if let priorIdentity = NSManagedObject.managedObjectWithEntityName(IdentityClassNameKey, predicate: predicate, context: context) {
                    return
                }
                
                if let newIdentity = NSEntityDescription.insertNewObjectForEntityForName(IdentityClassNameKey, inManagedObjectContext: context) as? Identity {
                    
                    newIdentity.name      = name
                    newIdentity.lockKey   = lockKey
                    newIdentity.masterKey = securedMasterKey!
                    newIdentity.unlockKey = securedUnlockKey!

                    bundle = (newIdentity, rescueCodeBundle!.string)
                }
            })
            
            return bundle
        }
        
        return nil
    }
    
    private class func rescueCodeBundleFromSeed(seed: NSData) -> (string: String, data: NSData)? {
        let requiredBytes = 32
        
        if seed.length < requiredBytes {
            return nil
        }
        
        let rescueCodeString = NSString.rescueCodeFromData(seed)
        let rescueCodeData   = rescueCodeString?.dataUsingEncoding(NSASCIIStringEncoding)
        
        if rescueCodeData == nil || rescueCodeData == nil {
            return nil
        }
        
        return (rescueCodeString! as String, rescueCodeData!)
    }
    
    private class func createIdentity(name: String, context: NSManagedObjectContext) -> Identity?
    {
        var newIdentity: Identity?
        
        // Try and create the identity
        context.performBlockAndWait
        {
            // Check if Identity with same name exists
            let predicate        = NSPredicate(format: "%K == %@", argumentArray: [IdentityPropertyNameKey, name])
            if let priorIdentity = NSManagedObject.managedObjectWithEntityName(IdentityClassNameKey, predicate: predicate, context: context) {
                return
            }
            
            newIdentity = NSEntityDescription.insertNewObjectForEntityForName(IdentityClassNameKey, inManagedObjectContext: context) as? Identity
            newIdentity?.name = name
        }
        return newIdentity
    }
    
    private class func createSecureStores(inout unlockKey: NSData?, unlockPasswordData: NSData, inout masterKey: NSData, masterKeyPasswordData: NSData, context: NSManagedObjectContext) -> (securedUnlockKey: GCMStore, securedMasterKey: XORStore)?
    {
        // Encrypt sensitive keys
        var securedUnlockKey: GCMStore?
        var securedMasterKey: XORStore?
        
        let threadGroup = dispatch_group_create()
        dispatch_group_enter(threadGroup)
        dispatch_group_enter(threadGroup)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
        {
                securedUnlockKey = GCMStore.createGCMStore(&unlockKey, password: unlockPasswordData, context: context)
                dispatch_group_leave(threadGroup)
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
        {
                securedMasterKey = XORStore.createXORStore(&masterKey, password: masterKeyPasswordData, storageType: .Local, context: context)
                dispatch_group_leave(threadGroup)
        }
        
        dispatch_group_wait(threadGroup, DISPATCH_TIME_FOREVER)
        
        if securedUnlockKey != nil && securedMasterKey != nil {
            return (securedUnlockKey!, securedMasterKey!)
        }
        return nil
    }
    
    class func createIdentity(let name: String, inout password: String, inout seed: NSData, touchID: Bool, let context: NSManagedObjectContext) -> (identity: Identity, rescueCode: String)?
    {
        if seed.length != 64 { return nil }
        
        let identitySeed   = seed.subdataWithRange(NSRange(location: 0, length: 32))
        let rescueCodeSeed = seed.subdataWithRange(NSRange(location: 32, length: 32))
        
        
        // Try and create an identity with that name
        // Use the first 256-bits (32bytes) for seeding the identity lock and unlock keypair
        if var
            identity             = Identity.createIdentity(name, context: context),
            rescueCodeBundle     = Identity.rescueCodeBundleFromSeed(rescueCodeSeed),
            passwordData         = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false),
            (unlockKey, lockKey) = Ed25519.keyPairFromSeed(identitySeed),
            masterKey            = EnHash.sha256(unlockKey, iterations: 16)
        {
            var optionalUnlockKey: NSData? = unlockKey // needed to satify CGMStore inout
            
            if let
                securedUnlockKey = GCMStore.createGCMStore(&optionalUnlockKey, password: rescueCodeBundle.data, context: context),
                securedMasterKey = XORStore.createXORStore(&masterKey, password: passwordData, storageType: .Local, context: context)
            {
                identity.lockKey   = lockKey
                identity.settings  = Settings.createSettings(touchID: touchID, context: context)
                identity.masterKey = securedMasterKey
                identity.unlockKey = securedUnlockKey
                
                // decrypt masterkey to set keychain
                if touchID { identity.masterKey.decryptCipherTextWithPasswordData(passwordData) }
                
                identitySeed.secureMemZero()
                rescueCodeSeed.secureMemZero()
                rescueCodeBundle.data.secureMemZero()
                passwordData.secureMemZero()
                unlockKey.secureMemZero()
                masterKey.secureMemZero()
                
                return (identity, rescueCodeBundle.string)
            }
        }
        return nil
    }
}