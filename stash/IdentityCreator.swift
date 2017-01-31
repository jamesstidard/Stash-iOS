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
    class func createIdentity(_ name: String, password: inout String, seed: inout Data, context: NSManagedObjectContext) -> (identity: Identity, rescueCode: String)?
    {
        if seed.count != 64 {
            return nil
        }
        
        // Use the first 256-bits (32bytes) for seeding the identity lock and unlock keypair
        let identitySeed     = seed.subdata(in: NSRange(location: 0, length: 32))
        let rescueCodeSeed   = seed.subdata(in: NSRange(location: 32, length: 32))
        let rescueCodeBundle = Identity.rescueCodeBundleFromSeed(rescueCodeSeed)
        let passwordData     = password.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        if rescueCodeBundle == nil || passwordData == nil {
            return nil
        }
        
        if let (var unlockKey, var lockKey) = Ed25519.keyPairFromSeed(identitySeed) {
            var optionalUnlockKey: Data? = unlockKey // needed to satify CGMStore inout
            
            var masterKey = EnHash.sha256(optionalUnlockKey!, iterations: 16)
            
            if masterKey == nil {
                return nil
            }
            
            // Send both keys off to generate on different thread
            var securedUnlockKey: GCMStore?
            var securedMasterKey: XORStore?
            
            let threadGroup = DispatchGroup()
            threadGroup.enter()
            threadGroup.enter()
            
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: {
                securedUnlockKey = GCMStore.createGCMStore(&optionalUnlockKey, password: rescueCodeBundle!.data, context: context)
                threadGroup.leave()
            })
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: {
                securedMasterKey = XORStore.createXORStore(&masterKey!, password: passwordData!, storageType: .local, context: context)
                threadGroup.leave()
            })
        
            threadGroup.wait(timeout: DispatchTime.distantFuture)
            
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
            
            context.performAndWait({
                // Check if Identity with same name exists
                let predicate        = NSPredicate(format: "%K == %@", argumentArray: [IdentityPropertyNameKey, name])
                if let priorIdentity = NSManagedObject.managedObjectWithEntityName(IdentityClassNameKey, predicate: predicate, context: context) {
                    return
                }
                
                if let newIdentity = NSEntityDescription.insertNewObject(forEntityName: IdentityClassNameKey, into: context) as? Identity {
                    
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
    
    fileprivate class func rescueCodeBundleFromSeed(_ seed: Data) -> (string: String, data: Data)? {
        let requiredBytes = 32
        
        if seed.count < requiredBytes {
            return nil
        }
        
        let rescueCodeString = NSString.rescueCodeFromData(seed)
        let rescueCodeData   = rescueCodeString?.data(using: String.Encoding.ascii)
        
        if rescueCodeData == nil || rescueCodeData == nil {
            return nil
        }
        
        return (rescueCodeString! as String, rescueCodeData!)
    }
    
    fileprivate class func createIdentity(_ name: String, context: NSManagedObjectContext) -> Identity?
    {
        var newIdentity: Identity?
        
        // Try and create the identity
        context.performAndWait
        {
            // Check if Identity with same name exists
            let predicate        = NSPredicate(format: "%K == %@", argumentArray: [IdentityPropertyNameKey, name])
            if let priorIdentity = NSManagedObject.managedObjectWithEntityName(IdentityClassNameKey, predicate: predicate, context: context) {
                return
            }
            
            newIdentity = NSEntityDescription.insertNewObject(forEntityName: IdentityClassNameKey, into: context) as? Identity
            newIdentity?.name = name
        }
        return newIdentity
    }
    
    fileprivate class func createSecureStores(_ unlockKey: inout Data?, unlockPasswordData: Data, masterKey: inout Data, masterKeyPasswordData: Data, context: NSManagedObjectContext) -> (securedUnlockKey: GCMStore, securedMasterKey: XORStore)?
    {
        // Encrypt sensitive keys
        var securedUnlockKey: GCMStore?
        var securedMasterKey: XORStore?
        
        let threadGroup = DispatchGroup()
        threadGroup.enter()
        threadGroup.enter()
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async
        {
                securedUnlockKey = GCMStore.createGCMStore(&unlockKey, password: unlockPasswordData, context: context)
                threadGroup.leave()
        }
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async
        {
                securedMasterKey = XORStore.createXORStore(&masterKey, password: masterKeyPasswordData, storageType: .local, context: context)
                threadGroup.leave()
        }
        
        threadGroup.wait(timeout: DispatchTime.distantFuture)
        
        if securedUnlockKey != nil && securedMasterKey != nil {
            return (securedUnlockKey!, securedMasterKey!)
        }
        return nil
    }
    
    class func createIdentity(_ name: String, password: inout String, seed: inout Data, touchID: Bool, context: NSManagedObjectContext) -> (identity: Identity, rescueCode: String)?
    {
        if seed.count != 64 { return nil }
        
        let identitySeed   = seed.subdata(in: NSRange(location: 0, length: 32))
        let rescueCodeSeed = seed.subdata(in: NSRange(location: 32, length: 32))
        
        
        // Try and create an identity with that name
        // Use the first 256-bits (32bytes) for seeding the identity lock and unlock keypair
        if var
            identity             = Identity.createIdentity(name, context: context),
            var rescueCodeBundle     = Identity.rescueCodeBundleFromSeed(rescueCodeSeed),
            var passwordData         = password.data(using: String.Encoding.utf8, allowLossyConversion: false),
            var (unlockKey, lockKey) = Ed25519.keyPairFromSeed(identitySeed),
            var masterKey            = EnHash.sha256(unlockKey, iterations: 16)
        {
            var optionalUnlockKey: Data? = unlockKey // needed to satify CGMStore inout
            
            if let
                securedUnlockKey = GCMStore.createGCMStore(&optionalUnlockKey, password: rescueCodeBundle.data, context: context),
                let securedMasterKey = XORStore.createXORStore(&masterKey, password: passwordData, storageType: .local, context: context)
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
