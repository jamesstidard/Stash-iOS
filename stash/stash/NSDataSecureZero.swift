//
//  NSDataSecureZero.swift
//  stash
//
//  Created by James Stidard on 07/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension NSData {
    
    func secureMemZero() {
        let selfPtr = UnsafeMutablePointer<UInt8>(self.bytes)
        sodium_memzero(selfPtr, UInt(self.length * sizeof(UInt8)))
    }
}