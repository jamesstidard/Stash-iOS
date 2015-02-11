//
//  XORStoreTests.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import XCTest

class XORStoreTests: ManagedObjectContextTestCase {
    
    let secret   = "secret"
    let password = "password"
    
    var xorStore: XORStore!
    var secretData: NSData!
    var passwordData: NSData!
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        passwordData = password.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
        secretData   = secret.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
        secretData   = Sha256.hash(secretData!)
        
        if let context = self.context {
            xorStore = XORStore.createXORStore(&secretData!, password: passwordData!, context: context)
        }
        
        XCTAssertNotNil(xorStore, "Unable to initialise XORStore for testing")
        XCTAssertNotNil(secretData, "Unable to initialise Secrect Data for XORStore testing")
        XCTAssertNotNil(passwordData, "Unable to initialise Password Data for XORStore testing")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDecrypt() {
        let decryptedData = xorStore.decryptCipherTextWithPassword(passwordData!)
        XCTAssertTrue((decryptedData?.isEqualToData(secretData!) == true), "XORStore didn't correctly decrypt data")
    }
    
    func testPasswordChange() {
        let newPassword = "newPassword"
        let newPasswordData = newPassword.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
    }
    
}
