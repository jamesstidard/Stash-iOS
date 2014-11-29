//
//  GyroHarvesterTests.swift
//  stash
//
//  Created by James Stidard on 29/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import XCTest

class GyroHarvesterTests: XCTestCase {

    var harvester = GyroHarvester()
    let machine = EntropyMachine()
    
    func testRegistersToMachine() {
        machine.addHarvester(&harvester)
        
        if let regMachine = harvester.registeredEntropyMachine {
            XCTAssert((ObjectIdentifier(regMachine) == ObjectIdentifier(machine)), "Machine registered with harvester")
        } else {
            XCTAssert(false, "machine not registered to Gyro Harvester");
        }
    }
    
    func testRegisteringToAdditionalMachine() {
        let secondHarvester = EntropyMachine()
        
        
    }
}
