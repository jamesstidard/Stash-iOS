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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

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
