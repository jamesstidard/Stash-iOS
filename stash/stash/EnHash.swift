//
//  EnHash.swift
//  stash
//
//  Created by James Stidard on 09/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

class EnHash {
    
    class func sha256(message: NSData, iterations: Int) -> NSData? {
        
        var finalOut: NSMutableData?
        var nextMessage = message
        
        for x in 1...iterations {
    
            if let out = Sha256.hash(nextMessage) as? NSMutableData {
                
                nextMessage = out
                
                if x == 1 {
                    finalOut = out.mutableCopy() as? NSMutableData
                } else {
                    finalOut = finalOut! ^ out
                }
            } else {
                return nil
            }
        }
        
        return finalOut
    }
}
