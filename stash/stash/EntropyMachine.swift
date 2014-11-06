//
//  EntropyMachine.swift
//  stash
//
//  Created by James Stidard on 06/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

class EntropyMachine {
    
    func start() {
        // start the hash function (close existing one if open)
        
        // switch hash state to on
        
        // get system information (like time)
        
        // addEntropy(sysInfo)
        
    }
    
    func addEntropy(entropy: NSData) {
        // make sure hashing func is open
        
        // perform some validation on data - not all 0's or 1's
        
        // format into c
        
        // push into hash func
    }
    
    func stop() {
        // switch hash state to off
        
        // close down hash
        
        // store (return?) result
    }
}
