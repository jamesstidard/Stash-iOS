//
//  OptionalOperatorChaining.swift
//  stash
//
//  Created by James Stidard on 11/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

infix operator +? { associativity left precedence 140 }
func +?(lhs: Int?, rhs: Int?) -> Int? {
    if let a = lhs, let b = rhs {
        return a + b
    }
    return nil
}

infix operator -? { associativity left precedence 140 }
func -?(lhs: Int?, rhs: Int?) -> Int? {
    if let a = lhs, let b = rhs {
        return a - b
    }
    return nil
}
