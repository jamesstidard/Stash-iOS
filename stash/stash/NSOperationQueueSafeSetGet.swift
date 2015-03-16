//
//  NSOperationQueueSafeSetGet.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension NSOperationQueue {
    
    func safelySet(setBlock: () -> Void) {
        
        let setOperation = NSBlockOperation(block: setBlock)
        
        self.addOperationWith(qualityOfService: .UserInitiated,
                                      priority: .VeryHigh,
                             waitUntilFinished: false,
                                operationBlock: setOperation)
    }
}