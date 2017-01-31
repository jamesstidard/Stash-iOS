//
//  NSOperationQueueSafeSetGet.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension OperationQueue {
    
    func safelySet(_ setBlock: @escaping () -> Void) {
        
        let setOperation = BlockOperation(block: setBlock)
        
        self.addOperationWith(qualityOfService: .userInitiated,
                                      priority: .veryHigh,
                             waitUntilFinished: false,
                                operationBlock: setOperation)
    }
}
