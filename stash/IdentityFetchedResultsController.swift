//
//  IdentityFetchedResultsController.swift
//  stash
//
//  Created by James Stidard on 11/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import CoreData

extension Identity
{
    class func fetchedResultsController(
        _ context: NSManagedObjectContext,
        sortDescriptors sorts: [NSSortDescriptor],
        sectionNameKeyPath keyPath: String?,
        cacheName: String?,
        delegate: NSFetchedResultsControllerDelegate,
        fetchLimit: Int) -> NSFetchedResultsController<NSFetchRequestResult>
    {
        let request             = NSFetchRequest<NSFetchRequestResult>(entityName: IdentityClassNameKey)
        request.sortDescriptors = sorts
        
        let identitiesFRC = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: cacheName)
        identitiesFRC.delegate = delegate
        identitiesFRC.fetchRequest.fetchLimit = fetchLimit
        return identitiesFRC
    }
    
    class func fetchedResultsController(
        _ context: NSManagedObjectContext,
        delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<NSFetchRequestResult>
    {
        let sorts = [NSSortDescriptor(key: IdentityPropertyNameKey, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        return self.fetchedResultsController(
            context,
            sortDescriptors: sorts,
            sectionNameKeyPath: nil,
            cacheName: nil,
            delegate: delegate,
            fetchLimit: 0)
    }
}
