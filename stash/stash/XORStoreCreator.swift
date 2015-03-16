//
//  XORStoreCreator.swift
//  stash
//
//  Created by James Stidard on 09/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

let XORStoreClassNameKey = "XORStore"

extension XORStore {
    
    class func createXORStore(inout sensitiveData: NSData, password: NSData, context: NSManagedObjectContext) -> XORStore? {
        
        var store: XORStore?
        
        // make sure the plaintext is the same length as the hashed password so they can be safely XORd
        if let var newKeyBundle = XORStore.makeKeyFromPassword(password)
            where newKeyBundle.key.length == sensitiveData.length {
                
            // Create the new store and assign its properties
            context.performBlockAndWait {
                if var newStore = NSEntityDescription.insertNewObjectForEntityForName(XORStoreClassNameKey, inManagedObjectContext: context) as? XORStore {
                        
                    newStore.ciphertext         = sensitiveData ^ newKeyBundle.key
                    newStore.scryptIterations   = Int64(newKeyBundle.i)
                    newStore.scryptMemoryFactor = Int64(newKeyBundle.N)
                    newStore.scryptSalt         = newKeyBundle.salt
                    newStore.verificationTag    = newKeyBundle.tag
                        
                    store = newStore
                }
            }
        }
        
        return store
    }
}