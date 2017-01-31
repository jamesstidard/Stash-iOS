//
//  NSDataSecureZero.swift
//  stash
//
//  Created by James Stidard on 07/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension Data {
    
    func secureMemZero() {
        let selfPtr = UnsafeMutablePointer<UInt8>(mutating: (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count))
        sodium_memzero(selfPtr, self.count * MemoryLayout<UInt8>.size)
    }
}
