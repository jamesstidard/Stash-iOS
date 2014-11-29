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
    
    func testHookingToHarvester() {
        self.harvester.registeredEntropyMachine = machine
        
        if let regMachine = self.harvester.registeredEntropyMachine {
            XCTAssert(ObjectIdentifier(regMachine) == ObjectIdentifier(machine), "Machine registered with harvester")
        } else {
            XCTAssert(false, "Machine didn't register with harvester")
        }
    }
    
    func testReplacingMachine() {
        let secondMachine = EntropyMachine()
        self.harvester.registeredEntropyMachine = machine
        self.harvester.registeredEntropyMachine = secondMachine
        
        if let regMachine = self.harvester.registeredEntropyMachine {
            XCTAssert(ObjectIdentifier(regMachine) == ObjectIdentifier(secondMachine), "second Machine registered with harvester")
        } else {
            XCTAssert(false, "second Machine didn't register with harvester")
        }
    }
    
    func testRunningBool() {
        harvester.start()
        XCTAssert(harvester.isRunning, "Running bool set")
    }
    
    func testStoppingBool() {
        XCTAssert(!harvester.isRunning, "Running bool initially false")
        harvester.start()
        harvester.stop()
        XCTAssert(!harvester.isRunning, "Running bool turned off after been started")
    }
    
    
}
