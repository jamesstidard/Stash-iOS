//
//  NSOperationQueueHelper.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension OperationQueue {
    
    func addOperationWith(qualityOfService qos: QualityOfService,
                                      priority: Operation.QueuePriority,
                        waitUntilFinished wait: Bool,
                          operationBlock block: BlockOperation)
    {
        block.qualityOfService = qos
        block.queuePriority    = priority
        
        self.addOperations([block], waitUntilFinished: wait)
    }
    
    func addOperationWith(qualityOfService qos: QualityOfService,
                                      priority: Operation.QueuePriority,
                        waitUntilFinished wait: Bool,
                                         block: @escaping () -> Void)
    {
        let operationBlock = BlockOperation(block: block)
        
        operationBlock.qualityOfService = qos
        operationBlock.queuePriority    = priority
        
        self.addOperations([operationBlock], waitUntilFinished: wait)
    }
}
