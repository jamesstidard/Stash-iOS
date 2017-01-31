//
//  NSDataFromMultipleObjects.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

extension Data {
    
    static func data<T>(usingLeastSignificantBytes lsb: Int, fromValues values: [T], excludeSign: Bool) -> Data {
        var lsb = lsb
        var data = NSMutableData()
        
        // make sure not out of bounds of type
        lsb = min(lsb, sizeof(T))
        lsb = max(lsb, 0)
        
        for value in values {
            var bytes = reverse(toByteArray(value))
            if excludeSign { bytes.remove(at: 0) }
            data.append(bytes, length: lsb)
        }
        
        return data as Data
    }
    
    static func data<T>(usingLeastSignificantBytes lsb: Int, fromValues values: [T]) -> Data {
        let lsb = lsb
       return data(usingLeastSignificantBytes: lsb, fromValues: values, excludeSign: false)
    }
    
    static func data<T>(_ values: [T]) -> Data {
        return data(usingLeastSignificantBytes: MemoryLayout<T>.size, fromValues: values)
    }
    
    private static func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafePointer(to: &value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: MemoryLayout<T>.size))
        }
    }
}
