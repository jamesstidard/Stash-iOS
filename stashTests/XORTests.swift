//
//  XORTests.swift
//  stash
//
//  Created by James Stidard on 13/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData
import XCTest

class XORTests: CoreDataTestCase {

    lazy var context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.coordinator
        return context
        }()
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        SodiumUtilities.initialise()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

//    Name space issue...
//    func testSensitiveDataCorrectlyStored() {
//        if
//            var sensitiveData   = SodiumUtilities.randomBytes(32),
//            let passwordData    = SodiumUtilities.randomBytes(32),
//            var xorStore        = XORStore.createXORStore(&sensitiveData, password: passwordData, context: self.context),
//            let newPasswordData = passwordData.copy() as? NSData,
//            let decryptedData   = xorStore.decryptCipherTextWithPassword(newPasswordData)
//        {
//            XCTAssertEqual(sensitiveData, decryptedData, "Decrypted data was not the sam as when it was encrypted")
//        }
//        else {
//            XCTFail("Couldn't encrypt data")
//        }
//    }
}
