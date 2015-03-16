//
//  NSDataFromMultipleObjects.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension NSData {
    
    class func data<T>(var usingLeastSignificantBytes lsb: Int, fromValues values: [T], excludeSign: Bool) -> NSData {
        var data = NSMutableData()
        
        // make sure not out of bounds of type
        lsb = min(lsb, sizeof(T))
        lsb = max(lsb, 0)
        
        for value in values {
            var bytes = reverse(toByteArray(value))
            if excludeSign { bytes.removeAtIndex(0) }
            data.appendBytes(bytes, length: lsb)
        }
        
        return data
    }
    
    class func data<T>(var usingLeastSignificantBytes lsb: Int, fromValues values: [T]) -> NSData {
       return data(usingLeastSignificantBytes: lsb, fromValues: values, excludeSign: false)
    }
    
    class func data<T>(values: [T]) -> NSData {
        return data(usingLeastSignificantBytes: sizeof(T), fromValues: values)
    }
    
    private class func toByteArray<T>(var value: T) -> [UInt8] {
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
        }
    }
}