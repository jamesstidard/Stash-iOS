//
//  CoreDataTestCase.swift
//  stash
//
//  Created by James Stidard on 13/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData
import XCTest

class CoreDataTestCase: XCTestCase {

    
    let storeType: String              = NSSQLiteStoreType
    let storeClass: AnyClass?          = nil
    var storeOptions: [String:String]? = nil
    lazy var storeURL: NSURL           = {
        let manager     = NSFileManager.defaultManager()
        let directories = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        var storeURL    = directories.last as! NSURL
        return storeURL.URLByAppendingPathComponent("testModel.sqlite")
        }()
    
    var coordinator: NSPersistentStoreCoordinator?
    
    // MARK: - Life Cycle
    override func setUp()
    {
        super.setUp()
        
        if let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(forClass: self.dynamicType)])
        {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            
            if let customStore: AnyClass = self.storeClass {
                NSPersistentStoreCoordinator.registerStoreClass(customStore, forStoreType: self.storeType)
            }
            
            self.coordinator = persistentStoreCoordinator
            
            var error: NSError?
            NSFileManager.defaultManager().removeItemAtURL(self.storeURL, error: &error)
            if self.coordinator?.addPersistentStoreWithType(self.storeType, configuration: nil, URL: self.storeURL, options: self.storeOptions, error: &error) == nil {
                XCTFail("Could not add store, \(error)")
            }
        } else { XCTFail("Could not get managed object model from \(self.dynamicType)") }
    }
    
    override func tearDown()
    {
        var error: NSError?
        
        let store = self.coordinator?.persistentStoreForURL(self.storeURL)
        if store != nil {
            self.coordinator?.removePersistentStore(store!, error: &error)
        }
        
        NSFileManager.defaultManager().removeItemAtURL(self.storeURL, error: &error)
        if let customStore: AnyClass = self.storeClass {
            NSPersistentStoreCoordinator.registerStoreClass(nil, forStoreType: self.storeType)
        }
        
        super.tearDown()
    }
    
    
    // MARK: - Tests
//    func testFetchDoesNotThrowException()
//    {
//        let context = NSManagedObjectContext(concurrencyType: .ConfinementConcurrencyType)
//        context.persistentStoreCoordinator = self.coordinator
//        
//        if let entity: AnyObject = context.persistentStoreCoordinator?.managedObjectModel.entities.last {
//            let request = NSFetchRequest(entityName: entity.name)
//            request.predicate = nil
//            
//            var error: NSError?
//            context.executeFetchRequest(request, error: &error)
//            
//            XCTAssertNil(error, "Error fetching: \(error)")
//        }
//    }

}
