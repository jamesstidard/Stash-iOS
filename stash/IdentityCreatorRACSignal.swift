//
//  IdentityCreatorRACSignal.swift
//  stash
//
//  Created by James Stidard on 24/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation
import CoreData

extension Identity
{
    // Reactive cocoa wrapper
    class func createIdentitySignal(_ name: String, password:inout String, seed: inout Data, touchID: Bool, context: NSManagedObjectContext) -> RACSignal
    {
        let subject           = RACSubject()
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType, parentContext: context)
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async
        {
            if var result = self.createIdentity(name, password: &password, seed: &seed, touchID: touchID, context: backgroundContext)
            {
                // save the background context so we can return the equavilent on the main context
                backgroundContext.save(nil)
                result.identity = context.object(with: result.identity.objectID) as! Identity
                
                let tuple = RACTuple(objectsFrom: [result.identity, result.rescueCode])
                subject.sendNext(tuple)
                subject.sendCompleted()
            }
            else
            {
                subject.sendError(NSError(domain: "com.stidard.stash",
                                            code: 0,
                                        userInfo: [NSLocalizedFailureReasonErrorKey:"Couldn't create identity"]))
            }
        }
        
        return subject
    }
}
