//
//  NSDataXOR.swift
//  stash
//
//  Created by James Stidard on 29/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

infix operator ^ { associativity left precedence 140 }
func ^(left: NSData, right: NSData) -> NSData {
    var result    = left.mutableCopy() as! NSMutableData
    var resultPtr = UnsafeMutablePointer<UInt8>(result.bytes)
    var rightPtr  = UnsafeMutablePointer<UInt8>(right.bytes)
    var leftPtr   = UnsafeMutablePointer<UInt8>(left.bytes)
    
    for byte in 0..<left.length {
        resultPtr[byte] = rightPtr[byte] ^ leftPtr[byte]
    }
    
    return result as NSData
}

func ^(left: NSMutableData, right: NSMutableData) -> NSMutableData {
    var result    = left.mutableCopy() as! NSMutableData
    var resultPtr = UnsafeMutablePointer<UInt8>(result.bytes)
    var rightPtr  = UnsafeMutablePointer<UInt8>(right.bytes)
    var leftPtr   = UnsafeMutablePointer<UInt8>(left.bytes)
    
    for byte in 0..<left.length {
        resultPtr[byte] = rightPtr[byte] ^ leftPtr[byte]
    }
    
    return result as NSMutableData
}