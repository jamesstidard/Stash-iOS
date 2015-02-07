//
//  IdentityCreator.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

let IdentityClassNameKey = "Identity"
let IdentityPropertyNameKey = "name"

extension Identity
{
    class func createIdentity(let name: String, let seed: NSData, let context: NSManagedObjectContext) -> Identity?
    {
        var identity: Identity?
        
        if seed.length != 64 {
            return nil
        }
        
        // Use the first 256-bits (32bytes) for seeding the identity lock and unlock keypair
        let identitySeed = seed.subdataWithRange(NSRange(location: 0, length: 32))
        
        if let keyPair = Ed25519.keyPairFromSeed(identitySeed) {
            
            // Check if Identity with same name exists
            let predicate     = NSPredicate(format: "%K == %@", argumentArray: [IdentityPropertyNameKey, name])
            let priorIdentity = NSManagedObject.managedObjectWithEntityName(IdentityClassNameKey, predicate: predicate, context: context)
            
            
            if priorIdentity == nil
            {
                // No Identity with the same name? Insert Identity
                let insertedIdentity = NSEntityDescription.insertNewObjectForEntityForName(IdentityClassNameKey, inManagedObjectContext: context) as Identity
                
                insertedIdentity.name      = name;
                insertedIdentity.unlockKey = keyPair.secretKey
                insertedIdentity.lockKey   = keyPair.publicKey
                
                identity = insertedIdentity
            }
        }
        
        
        
        // Use the second 256-bits (32bytes) for generating the rescue code
        let rescueCodeSeed = seed.subdataWithRange(NSRange(location: 32, length: 32))
        
        // get ascii 24 digit string
        
        // generate salt 32 byte salt
        
        // enscrypt ascii string with salt to generate encryption key for unlockKey
        
        // GCM entrypt unlockKey, store and securly delete unencrypted unlockKey
        
        
        // enHash UnlockKey to derive master key
        
        // generate anouther 32byte salt
        
        // enscrypt user identity password and salt to generate key for master key
        
        // 

        
        
        
        
        return identity
    }
    
    
}