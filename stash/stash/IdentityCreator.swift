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
    class func createIdentity(let name: String, password: String, let seed: NSData, let context: NSManagedObjectContext) -> (identity: Identity, rescueCode: String)?
    {
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
                let identity = NSEntityDescription.insertNewObjectForEntityForName(IdentityClassNameKey, inManagedObjectContext: context) as Identity
                
                identity.name      = name;
                identity.unlockKey = keyPair.secretKey
                identity.lockKey   = keyPair.publicKey
                
                // Use the second 256-bits (32bytes) for generating the rescue code
                let rescueCodeSeed = seed.subdataWithRange(NSRange(location: 32, length: 32))
                
                // get ascii 24 digit string
                let rescueCode          = NSString.rescueCodeFromData(rescueCodeSeed)
                let rescueCodeASCIIData = rescueCode?.dataUsingEncoding(NSASCIIStringEncoding)
                
                // generate salt 32 byte salt
                if let salt = SodiumUtilities.randomBytes(32) {
                    identity.unlockKeySalt = salt
                    
                    // enscrypt ascii string with salt to generate encryption key for unlockKey
                    if var unlockEncryptionKey = EnScrypt.salsa208Sha256(rescueCodeASCIIData, salt: salt, N: 512, r: 256, p: 1, i: 1) {
                        // GCM entrypt unlockKey, store and securly delete unencrypted unlockKey
                        if let result = AesGcm.encrypt256(&unlockEncryptionKey, sensitiveData: &identity.unlockKey, additionalData: nil, iv: nil, tagByteLength: 16) {
                            
                            if let tag = result.tag {
                                identity.encryptedUnlockKeyVerificationTag = tag
                            }
                            if let encryptedUnlockKey = result.cipherData {
                                identity.encryptedUnlockKey = encryptedUnlockKey
                            }
                            
                            // enHash UnlockKey to derive master key
                            if let masterKey = EnHash.sha256(identity.unlockKey!, iterations: 16) {
                                identity.masterKey = masterKey
                            }
                            
                            // generate anouther 32byte salt and IV
                            let passwordData = password.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)
                            if let passwordSalt = SodiumUtilities.randomBytes(8) {
                                identity.masterKeyPasswordSalt = passwordSalt
                                
                                // using salt and users password generate the key to encrypt with
                                if let masterEncryptionKey = EnScrypt.salsa208Sha256(passwordData, salt: passwordSalt, N: 512, r: 256, p: 1, i: 1) {
                                    
                                    if let passwordVerfier = Sha256.hash(masterEncryptionKey) {
                                        // just keep the lower 128 bits to verifify
                                        identity.masterKeyPasswordVerifier = passwordVerfier.subdataWithRange(NSRange(location: 0, length: passwordVerfier.length/2))
                                    }
                                }
                            }
                        }
                    }
                    
                    if rescueCode != nil {
                        return (identity, rescueCode!)
                    }
                }
            }
        }

        return nil
    }
    
    
}