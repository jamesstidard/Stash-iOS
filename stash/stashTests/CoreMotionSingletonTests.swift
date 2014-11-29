//
//  CoreMotionSingletonTests.swift
//  stash
//
//  Created by James Stidard on 28/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import CoreMotion
import XCTest

class CoreMotionSingletonTests: XCTestCase {

    func testSingleton() {
        let instanceOne = CMMotionManager.sharedInstance
        let instanceTwo = CMMotionManager.sharedInstance
        
        if ObjectIdentifier(instanceOne) == ObjectIdentifier(instanceTwo) {
            XCTAssertTrue(true, "Single Instance of Singleton")
        } else {
            XCTAssertTrue(false, "CoreMotion singleton extention creates multiple instances")
        }
    }
}
