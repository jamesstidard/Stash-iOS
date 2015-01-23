//
//  IdentityCreator.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

extension Identity
{
    class func createIdentity(let name: String, let seed: NSData, let context: NSManagedObjectContext) -> Identity?
    {
        if let keyPair = SodiumWrapper.ed25519KeyPairFromSeed(seed) {
            
            // Check if Identity with same name exists
            let predicate     = NSPredicate(format: "@K == %@", argumentArray: [name])
            let priorIdentity = NSManagedObject.managedObjectWithEntityName("Identity", predicate: predicate, context: context)
            
            
            if priorIdentity != nil
            {
                // No Identity with the same name? Insert Identity
                let identity = NSEntityDescription.insertNewObjectForEntityForName("Identity", inManagedObjectContext: context) as Identity
                
                identity.name      = name;
                identity.unlockKey = keyPair.secretKey
                identity.lockKey   = keyPair.publicKey
                
                return identity
            }
        }
        
        return nil
    }
    
    
}