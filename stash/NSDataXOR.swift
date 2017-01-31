//
//  NSDataXOR.swift
//  stash
//
//  Created by James Stidard on 29/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

infix operator ^ { associativity left precedence 140 }
func ^(left: Data, right: Data) -> Data {
    var result    = (left as NSData).mutableCopy() as! NSMutableData
    var resultPtr = UnsafeMutablePointer<UInt8>(mutating: result.bytes.bindMemory(to: UInt8.self, capacity: result.count))
    var rightPtr  = UnsafeMutablePointer<UInt8>(mutating: (right as NSData).bytes.bindMemory(to: UInt8.self, capacity: right.count))
    var leftPtr   = UnsafeMutablePointer<UInt8>(mutating: (left as NSData).bytes.bindMemory(to: UInt8.self, capacity: left.count))
    
    for byte in 0..<left.count {
        resultPtr[byte] = rightPtr[byte] ^ leftPtr[byte]
    }
    
    return result as Data
}

func ^(left: NSMutableData, right: NSMutableData) -> NSMutableData {
    var result    = left.mutableCopy() as! NSMutableData
    var resultPtr = UnsafeMutablePointer<UInt8>(mutating: result.bytes.bindMemory(to: UInt8.self, capacity: result.count))
    var rightPtr  = UnsafeMutablePointer<UInt8>(mutating: right.bytes.bindMemory(to: UInt8.self, capacity: right.count))
    var leftPtr   = UnsafeMutablePointer<UInt8>(mutating: left.bytes.bindMemory(to: UInt8.self, capacity: left.count))
    
    for byte in 0..<left.length {
        resultPtr[byte] = rightPtr[byte] ^ leftPtr[byte]
    }
    
    return result as NSMutableData
}
