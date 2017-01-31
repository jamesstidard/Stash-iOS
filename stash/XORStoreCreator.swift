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
    
    class func createXORStore(_ sensitiveData: inout Data, password: Data, storageType: EnScryptStorageType, context: NSManagedObjectContext) -> XORStore?
    {
        var store: XORStore?
        
        // make sure the plaintext is the same length as the hashed password so they can be safely XORd
        if let newKeyBundle = XORStore.makeKeyFromPassword(password, storageType: storageType),  newKeyBundle.key.count == sensitiveData.count
        {
            // Create the new store and assign its properties
            context.performAndWait {
                if var newStore = NSEntityDescription.insertNewObject(forEntityName: XORStoreClassNameKey, into: context) as? XORStore {
                    
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
