//
//  Stash.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation
import CoreData

class Stash {
    
    var context :NSManagedObjectContext?
    let mainBundle = NSBundle.mainBundle()
    
    
    class var sharedInstance :Stash {
        struct Singleton {
            static let instance = Stash()
        }
        return Singleton.instance
    }
    
    init() {
        setupCoreDataStack()
    }
    
    private func setupCoreDataStack() {
        // Create model object from data model
        if let modelURL = mainBundle.URLForResource("model", withExtension: "momd") {
            
            if let (model, storeCoordinator) = Stash.createModelAndCoordinator(modelURL) {
                
                // BACKGROUND: Attach stores in background as reading from disk / performing migration can take a long time
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    let storeURL = Stash.persistentStoreDiskURL()
                    let store    = Stash.attachStore(storeURL, toStoreCoordinator: storeCoordinator)
                    
                    // MAIN QUEUE: callback to main queue and setup context
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        self.context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                        self.context?.persistentStoreCoordinator = storeCoordinator;
                    })
                })
            }
        }
    }
    
    private class func attachStore(storeURL: NSURL, toStoreCoordinator coordinator: NSPersistentStoreCoordinator) -> NSPersistentStore?
    {
        var error: NSError?
        if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error) {
            return store
        } else {
            println("ERROR: Couldn't add store to coordinator: \(error?.description)")
            return nil
        }
    }
    
    private class func persistentStoreDiskURL() -> NSURL {
        // SQLite file stored in documents directory
        let fileManager    = NSFileManager.defaultManager()
        let directoryArray = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        var storeURL = directoryArray.last as NSURL
        return storeURL.URLByAppendingPathComponent("model.sqlite") // append file name of sql file
    }
    
    private class func createModelAndCoordinator(modelURL: NSURL) -> (NSManagedObjectModel, NSPersistentStoreCoordinator)? {
        if let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
               return (managedObjectModel, persistentStoreCoordinator)
        }
        return nil
    }
}

