//
//  NSStringRescueCode.swift
//  stash
//
//  Created by James Stidard on 07/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension NSString {
    
    class func rescueCodeFromData(_ data: Data) -> NSString?
    {
        let RescueCodeLength = 24
        
        if (data.count != 32) {
            println("rescueCodeFromData:encoding requires 32 bytes of data")
            return nil
        }
        
        
        var rescueCode        = NSMutableString()
        var dividend          = (data as NSData).mutableCopy() as! NSMutableData
        var remainder: UInt32 = 0
        
        for _ in 1...RescueCodeLength {
            remainder = dividend /% 10
            rescueCode.append("\(remainder)")
        }
        
        dividend.secureMemZero()
        remainder = 0
        
        
        return rescueCode
    }
}
