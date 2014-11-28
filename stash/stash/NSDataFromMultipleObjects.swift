//
//  NSDataFromMultipleObjects.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension NSData {
    
    class func dataFromMultipleObjects<T :AnyObject>(objects: T...) -> NSData {
        var data = NSMutableData()
        
        for object in objects {
            var varibleValue = object
            data.appendBytes(&varibleValue, length: sizeof(T))
        }
        
        return data
    }
}