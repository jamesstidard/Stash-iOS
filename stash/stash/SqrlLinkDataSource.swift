//
//  SqrlLinkDataSource.swift
//  stash
//
//  Created by James Stidard on 23/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

protocol SqrlLinkDataSource: class
{
    var sqrlLink: NSURL? { get }
}
