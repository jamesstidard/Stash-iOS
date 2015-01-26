//
//  StashSingletonTests.swift
//  stash
//
//  Created by James Stidard on 24/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import XCTest

class StashSingletonTests: XCTestCase {

    func testSingleton() {
        let instanceOne = Stash.sharedInstance
        let instanceTwo = Stash.sharedInstance
        
        if ObjectIdentifier(instanceOne) == ObjectIdentifier(instanceTwo) {
            XCTAssertTrue(true, "Single Instance of Singleton")
        } else {
            XCTAssertTrue(false, "CoreMotion singleton extention creates multiple instances")
        }
    }

}
