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
            
            var masterKey = EnHash.sha256(unlockKey!, iterations: 16)
            
            if unlockKey == nil || masterKey == nil {
                return nil
            }
            
            // Send both keys off to generate on different thread
            var securedUnlockKey: GCMStore?
            var securedMasterKey: XORStore?
            
            let threadGroup = dispatch_group_create()
            dispatch_group_enter(threadGroup)
            dispatch_group_enter(threadGroup)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                securedUnlockKey = GCMStore.createGCMStore(&unlockKey, password: rescueCodeBundle!.data, context: context)
                dispatch_group_leave(threadGroup)
            })
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                securedMasterKey = XORStore.createXORStore(&masterKey!, password: passwordData!, context: context)
                dispatch_group_leave(threadGroup)
            })
        
            dispatch_group_wait(threadGroup, DISPATCH_TIME_FOREVER)
            
            if securedUnlockKey == nil || securedMasterKey == nil {
                return nil
            }
            
            unlockKey!.secureMemZero()
            masterKey!.secureMemZero()
            identitySeed.secureMemZero()
            passwordData!.secureMemZero()
            rescueCodeSeed.secureMemZero()
            rescueCodeBundle!.data.secureMemZero()
            

            // Check if Identity with same name exists
            var bundle: (identity: Identity, rescueCode: String)?
            
            context.performBlockAndWait({
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
    
    class func rescueCodeBundleFromSeed(seed: NSData) -> (string: String, data: NSData)? {
        let requiredBytes = 32
        
        if seed.length < requiredBytes {
            return nil
        }
        
        let rescueCodeString = NSString.rescueCodeFromData(seed)
        let rescueCodeData   = rescueCodeString?.dataUsingEncoding(NSASCIIStringEncoding)
        
        if rescueCodeData == nil || rescueCodeData == nil {
            return nil
        }
        
        return (rescueCodeString!, rescueCodeData!)
    }
    
}