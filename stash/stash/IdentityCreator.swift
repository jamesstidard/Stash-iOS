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
        if seed.length != 64 {
            return nil
        }
        
        // Use the first 256-bits (32bytes) for seeding the identity lock and unlock keypair
        let identitySeed = NSData(bytes: seed.bytes, length: SodiumWrapper.Ed25519SeedBytes)
        
        if let keyPair = SodiumWrapper.ed25519KeyPairFromSeed(identitySeed) {
            
            // Check if Identity with same name exists
            let predicate     = NSPredicate(format: "%K == %@", argumentArray: [IdentityPropertyNameKey, name])
            let priorIdentity = NSManagedObject.managedObjectWithEntityName(IdentityClassNameKey, predicate: predicate, context: context)
            
            
            if priorIdentity == nil
            {
                // No Identity with the same name? Insert Identity
                let identity = NSEntityDescription.insertNewObjectForEntityForName(IdentityClassNameKey, inManagedObjectContext: context) as Identity
                
                identity.name      = name;
                identity.unlockKey = keyPair.secretKey
                identity.lockKey   = keyPair.publicKey
                
                return identity
            }
        }
        
        return nil
    }
    
    
}