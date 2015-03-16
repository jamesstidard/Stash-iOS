//
//  XORStoreTests.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

//import UIKit
//import XCTest
//import CoreData
//
//class XORStoreTests: ManagedObjectContextTestCase {
//    
//    let secret   = "secret"
//    let password = "password"
//    
//    var xorStore: XORStore?
//    var secretData: NSData!
//    var passwordData: NSData!
//    
//    
//    override func setUp() {
//        super.setUp()
//        
//        let settings = NSEntityDescription.insertNewObjectForEntityForName("Settings", inManagedObjectContext: self.context) as! Settings
//        
//        settings.hintLength = 4
//        println(settings.hintLength)
//        
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        passwordData = password.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
//        secretData   = secret.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
//        secretData   = Sha256.hash(secretData!)
//        
//        xorStore = XORStoreTests.createXORStore(&secretData!, password: passwordData!, context: context)
//    }
//    
//    private class func createXORStore(inout sensitiveData: NSData, password: NSData, context: NSManagedObjectContext) -> XORStore? {
//        
//        var store: XORStore?
//        
//        if let var newKeyBundle = XORStore.makeKeyFromPassword(password) {
//            
//            // make sure the plaintext is the same length as the hashed password so they can be safely XORd
//            if newKeyBundle.key.length == sensitiveData.length {
//                
//                // Create the new store and assign its properties
//                let newStore = NSEntityDescription.insertNewObjectForEntityForName(XORStoreClassNameKey, inManagedObjectContext: context) as! XORStore
//                        
//                newStore.ciphertext         = sensitiveData ^ newKeyBundle.key
//                newStore.scryptIterations   = Int64(newKeyBundle.i)
//                newStore.scryptMemoryFactor = Int64(newKeyBundle.N)
//                newStore.scryptSalt         = newKeyBundle.salt
//                newStore.verificationTag    = newKeyBundle.tag
//                        
//                store = newStore
//            }
//        }
//        
//        return store
//    }
//    
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//    
//    func testSetUp() {
//        XCTAssertNotNil(xorStore, "Unable to initialise XORStore for testing")
//        XCTAssertNotNil(secretData, "Unable to initialise Secrect Data for XORStore testing")
//        XCTAssertNotNil(passwordData, "Unable to initialise Password Data for XORStore testing")
//    }
//    
//    func testDecrypt() {
//        let decryptedData = xorStore?.decryptCipherTextWithPassword(passwordData!)
//        XCTAssertTrue((decryptedData?.isEqualToData(secretData!) == true), "XORStore didn't correctly decrypt data")
//    }
//    
//    func testPasswordChange() {
//        let newPassword = "newPassword"
//        let newPasswordData = newPassword.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
//        XCTAssertTrue(false, "finish implenentation")
//    }
//
//}
