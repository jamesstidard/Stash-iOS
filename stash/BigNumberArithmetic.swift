//
//  BigNumberArithmetic.swift
//  stash
//
//  Created by James Stidard on 07/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

infix operator /% { associativity left precedence 140 }
func /%(bigNumberData: inout NSMutableData, divisor: UInt32) -> UInt32 {
    
    // Get pointer to dividend data and allocate a big number type from it
    var bigNumberDataPtr = UnsafeMutablePointer<UInt8>(bigNumberData.mutableBytes)
    var bigNumber        = BN_bin2bn(bigNumberDataPtr, Int32(bigNumberData.length * sizeof(UInt8)), nil)
    
    // Perform combined division/modulus operation
    let remainder = BN_div_word(bigNumber, divisor)
    
    // Replace dividend with quotient data and zero out and free memory
    BN_bn2bin(bigNumber, bigNumberDataPtr)
    BN_clear_free(bigNumber)
    
    return remainder
}

func /%(dividend: Data, divisor: UInt32) -> (quotient: Data, remainder: UInt32) {
    var mutableQuatient = (dividend as NSData).mutableCopy() as! NSMutableData
    let remainder       = &mutableQuatient /% divisor
    let quotient        = mutableQuatient.copy() as! Data
    
    mutableQuatient.secureMemZero()
    return (quotient, remainder)
}
