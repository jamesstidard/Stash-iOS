//
//  NSOperationQueueHelper.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension NSOperationQueue {
    
    func addOperationWith(qualityOfService qos: NSQualityOfService,
                                      priority: NSOperationQueuePriority,
                        waitUntilFinished wait: Bool,
                          operationBlock block: NSBlockOperation)
    {
        block.qualityOfService = qos
        block.queuePriority = priority
        
        self.addOperations([block], waitUntilFinished: wait)
    }
}