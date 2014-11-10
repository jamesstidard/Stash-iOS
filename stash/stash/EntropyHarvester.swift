//
//  EntropyHarvester.swift
//  stash
//
//  Created by James Stidard on 10/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import Foundation

protocol EntropyHarvester {
    
    var isRunning: Bool { get }
    weak var registeredEntropyMachine: EntropyMachine? { get set }
    
    init(registerWith entropyMachine: EntropyMachine)
    
    func start()
    func stop()
}