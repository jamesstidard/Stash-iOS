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
        let N = EnScryptDefaultNCost
        let r = EnScryptDefaultRCost
        let p = EnScryptDefaultParallelisation
        let i = EnScryptDefaultIterations
        
        let saltBytes         = 32
        let verificationBytes = 16
        
        
        // Generate a random salt and hash with the plaintext password
        let salt = SodiumUtilities.randomBytes(saltBytes)
        var key  = EnScrypt.salsa208Sha256(password, salt: salt, N: N, r: r, p: p, i: i)
        // Quit if unable to generate key from hashing password
        if key == nil || salt == nil {
            return nil
        }
        
        
        // make sure the plaintext is the same length as the hashed password so they can be safely XORd
        if key?.length != sensitiveData.length {
            return nil
        }
        // Attach password by XORing
        let ciphertext = sensitiveData ^ key!
        // Store the first part of sequental hash on key for password verification
        var verificationTag = Sha256.hash(key!)?.subdataWithRange(NSRange(location: 0, length: verificationBytes))
        if verificationTag == nil {
            return nil
        }
        
        
        // Create the new store and assign its properties
        var newStore: XORStore!
        
        context.performBlockAndWait {
            newStore = NSEntityDescription.insertNewObjectForEntityForName(XORStoreClassNameKey, inManagedObjectContext: context) as XORStore
            
            newStore.ciphertext         = ciphertext
            newStore.scryptIterations   = i
            newStore.scryptMemoryFactor = N
            newStore.scryptSalt         = salt!
            newStore.verificationTag    = verificationTag!
        }
        
        return newStore
    }
}