//
//  NSOperationQueueSafeSetGet.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension NSOperationQueue {
    
    class func safelySet<T>(inout value: T, toValue: T, onQueue queue: NSOperationQueue) {
        queue.safelySet(&value, toValue: toValue)
    }
    
    class func safelyGet<T>(value: T, onQueue queue: NSOperationQueue) -> T {
        return queue.safelyGet(value)
    }
    
    func safelySet<T>(inout value: T, toValue: T) {
        let setOperation = NSBlockOperation { () -> Void in
            value = toValue
        }
        
        self.addOperationWith(qualityOfService: .UserInitiated,
                                      priority: .VeryHigh,
                             waitUntilFinished: false,
                                operationBlock: setOperation)
    }
    
    func safelyGet<T>(value: T) -> T {
        var result: T!
        
        let getOperation = NSBlockOperation { () -> Void in
            result = value
        }
        
        self.addOperationWith(qualityOfService: .UserInitiated,
                                      priority: .VeryHigh,
                             waitUntilFinished: true,
                                operationBlock: getOperation)
        
        return result
    }
}