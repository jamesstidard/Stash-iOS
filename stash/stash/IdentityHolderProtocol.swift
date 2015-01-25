//
//  IdentityHolderProtocol.swift
//  stash
//
//  Created by James Stidard on 25/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

@objc protocol IdentityHolder {
    var identity: Identity? { get set }
}