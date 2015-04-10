//
//  SodiumUtilities.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

var SodiumSuccess :Int32 { return 0 }

class SodiumUtilities {
    
    class func initialise() {
        sodium_init()
    }
    
    class func randomBytes(length: Int) -> NSData?
    {
        if length > 0 {
            
            if var bytes = NSMutableData(length: length) {
                var bytesPtr = UnsafeMutablePointer<UInt8>(bytes.bytes)
                randombytes_buf(bytesPtr, length)
                return bytes
            }
        }
        
        return nil
    }
}