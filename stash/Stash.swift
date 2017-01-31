//
//  Stash.swift
//  stash
//
//  Created by James Stidard on 23/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation
import CoreData

let StashPropertyContextKey = "context"

class Stash: NSObject {
    
    dynamic var context :NSManagedObjectContext? // dynamic so it can be KVO
    let mainBundle = Bundle.main
    
    
    class var sharedInstance :Stash {
        struct Singleton {
            static let instance = Stash()
        }
        return Singleton.instance
    }
    
    override init() {
        super.init()
        setupCoreDataStack()
    }
    
    fileprivate func setupCoreDataStack() {
        // Create model object from data model
        if let
            modelURL                  = mainBundle.url(forResource: "Model", withExtension: "momd"),
            let (model, storeCoordinator) = Stash.createModelAndCoordinator(modelURL)
        {
            // BACKGROUND: Attach stores in background as reading from disk / performing migration can take a long time
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
                let storeURL = Stash.persistentStoreDiskURL()
                let store    = Stash.attachStore(storeURL, toStoreCoordinator: storeCoordinator)
                    
                // MAIN QUEUE: callback to main queue and setup context
                DispatchQueue.main.sync(execute: {
                    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                    context.persistentStoreCoordinator = storeCoordinator;
                        
                    self.context = context
                })
            })
        }
    }
    
    fileprivate class func attachStore(_ storeURL: URL, toStoreCoordinator coordinator: NSPersistentStoreCoordinator) -> NSPersistentStore?
    {
        var error: NSError?
        if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error) {
            return store
        } else {
            println("ERROR: Couldn't add store to coordinator: \(error?.description)")
            return nil
        }
    }
    
    fileprivate class func persistentStoreDiskURL() -> URL {
        // SQLite file stored in documents directory
        let fileManager = FileManager.default
        let storeURL    = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.stidard.stash")!
        
        return storeURL.appendingPathComponent("model.sqlite") // append file name of sql file
    }
    
    fileprivate class func createModelAndCoordinator(_ modelURL: URL) -> (NSManagedObjectModel, NSPersistentStoreCoordinator)? {
        if let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            return (managedObjectModel, persistentStoreCoordinator)
        }
        return nil
    }
}

