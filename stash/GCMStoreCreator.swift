//
//  GCMStoreCreator.swift
//  stash
//
//  Created by James Stidard on 09/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

let GCMStoreClassNameKey = "GCMStore"

extension GCMStore {
    
    class func createGCMStore(_ sensitiveData: inout Data?, password: Data, context: NSManagedObjectContext) -> GCMStore? {
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
        if key == nil {
            return nil
        }
        
        
        // Encrypt data with key. Use default supplied nonce (initilisation vector)
        var nonce: Data?
        let resultBundle = AesGcm.encrypt256(&key!, sensitiveData: &sensitiveData, additionalData: nil, iv: &nonce, tagByteLength: verificationBytes)!
        // If unsuccessful then fail
        if resultBundle.cipherData == nil || resultBundle.tag == nil || nonce == nil {
            return nil
        }
        
        
        // Create a new GCMStore in the context and set it's properties
        var newStore: GCMStore!
        
        context.performAndWait {
            newStore = NSEntityDescription.insertNewObject(forEntityName: GCMStoreClassNameKey, into: context) as! GCMStore
            
            newStore.ciphertext         = resultBundle.cipherData!
            newStore.scryptIterations   = Int64(i)
            newStore.scryptMemoryFactor = Int64(N)
            newStore.scryptSalt         = salt!
            newStore.verificationTag    = resultBundle.tag!
            newStore.nonce              = nonce!
        }
        
        return newStore
    }
}
