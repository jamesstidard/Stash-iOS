//
//  EntropyHarvester.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

protocol EntropyHarvester {
    
    var isRunning: Bool { get }
    weak var registeredEntropyMachine: EntropyMachine? { get set }
    
    init(machine: EntropyMachine)
    
    func start()
    func stop()
}
