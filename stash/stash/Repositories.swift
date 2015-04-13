//
//  IdentityRepository.swift
//  stash
//
//  Created by James Stidard on 13/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

protocol IdentityRepository: class
{
    var identityBundle:(identity: Identity, password: String)? { get set }
}

protocol SqrlLinkRepository: class
{
    var sqrlLink: NSURL? { get set }
}