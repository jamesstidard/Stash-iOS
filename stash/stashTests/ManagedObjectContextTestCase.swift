//
//  ManagedObjectContextTestCase.swift
//  stash
//
//  Created by James Stidard on 11/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import XCTest
import CoreData

class ManagedObjectContextTestCase: XCTestCase {
    
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let bundle  = NSBundle(forClass: ManagedObjectContextTestCase.self)
        if let modelURL = bundle.URLForResource("Model", withExtension: "momd") {
            if let model = NSManagedObjectModel(contentsOfURL: modelURL) {
                let coord = NSPersistentStoreCoordinator(managedObjectModel: model)
                let store = coord.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
                let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                context.persistentStoreCoordinator = coord
                self.context = context
            }
        }
        
        XCTAssertNotNil(context, "Unable to initialise context for unit tests")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        self.context?.reset()
        super.tearDown()
    }
}
