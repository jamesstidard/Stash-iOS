//
//  entropyMachineTests.swift
//  stash
//
//  Created by James Stidard on 07/11/2014.
//  Copyright (c) 2014 James Stidard. All rights reserved.
//

import XCTest


class entropyMachineTests: XCTestCase {
    
    let entropyMachine = EntropyMachine()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExcesiveEntropy() {
        // This is an example of a functional test case.
        entropyMachine.start()
        
        let stringData = "some string data"
        
        if let data = stringData.dataUsingEncoding(NSUTF8StringEncoding) {
            
            for _ in 0...1000000 {
                entropyMachine.addEntropy(data)
            }
        }
        
        if let result = entropyMachine.stop() {
            XCTAssert(true, "Pass")
        } else {
            XCTAssert(false, "Failed exesive entropy test")
        }
    }
    
    func testUnquieHashWithSameInput() {
        let entropyMachine2 = EntropyMachine()
        
        entropyMachine.start()
        entropyMachine2.start()
        
        
        let stringData = "some string data"
        
        for machine in [entropyMachine, entropyMachine2] {
            
            if let data = stringData.dataUsingEncoding(NSUTF8StringEncoding) {
                for _ in 0...100 {
                    machine.addEntropy(data)
                }
            }
        }
        
        let result1 = entropyMachine.stop()
        if let result2 = entropyMachine2.stop() {
            XCTAssert(result1?.isEqualToData(result2) == false, "Hashes are equal when should unquie")
        } else {
            XCTAssert(false, "entropymachine 2 didn't return resulting hash")
        }
    }
    
    func testEntropyMachineReuse() {
        entropyMachine.start()
        let result = entropyMachine.stop()
        
        entropyMachine.start()
        if let result2 = entropyMachine.stop() {
            
            if result?.isEqualToData(result2) == false {
                XCTAssert(true, "Pass")
            } else {
                XCTAssert(false, "Failed: Result 2 maches result 1 on reuse of entropy machine")
            }
            
        } else {
            XCTAssert(false, "Failed: Unable to get result on second use of entropy machine")
        }
    }
    
    func testPriotityStopMachine() {
        entropyMachine.start()
        
        // Create some data to feed into entropy machine
        let stringData = "some string data"
        let data       = stringData.dataUsingEncoding(NSUTF8StringEncoding)
        var completedEntropyPush = false
        
        // Dispatch background thread to push data in
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            if (data != nil) {
                
                for _ in 0...1_000_000_000 {
                    self.entropyMachine.addEntropy(data!)
                }
                XCTAssert(false, "Finished pushing entropy before stop (with a higher priority) was called")
            } else {
                    XCTAssert(false, "Unable to create data to push")
            }
        })
        
        // wait a second for background thread to start pushing entropy
        // Assumes 1,000,000,000 entropy adding operations can't be made in under a second
        NSThread.sleepForTimeInterval(1)
        
        if let result = entropyMachine.stop() {
            XCTAssert(true, "Passed Stop() priority")
        }
    }
    
    func testThreadedAccess() {
        var threadGroup = dispatch_group_create()
        let stringData  = "some string data"
        let data        = stringData.dataUsingEncoding(NSUTF8StringEncoding)
        
        entropyMachine.start()
        
        for i in 0...10 {
            dispatch_group_enter(threadGroup)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                if (data != nil) {
                    for _ in 0...1_000 {
                        self.entropyMachine.addEntropy(data!)
                    }
                } else {
                    XCTAssert(false, "Unable to create data to push")
                }
                dispatch_group_leave(threadGroup)
            })
        }
        dispatch_group_wait(threadGroup, DISPATCH_TIME_FOREVER)
        
        if let result = entropyMachine.stop() {
            XCTAssert(true, "Passed Stop() priority")
        }
    }
    
    func testThreadedAccessWhileStillStreamingEntropy() {
        let stringData  = "some string data"
        let data        = stringData.dataUsingEncoding(NSUTF8StringEncoding)
        
        entropyMachine.start()
        
        for i in 0...10 {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                if (data != nil) {
                    for _ in 0...1_000_000_000 {
                        self.entropyMachine.addEntropy(data!)
                    }
                } else {
                    XCTAssert(false, "Unable to create data to push")
                }
            })
        }
        
        NSThread.sleepForTimeInterval(5)
        
        if let result = entropyMachine.stop() {
            XCTAssert(true, "Passed Stop() priority")
        }
    }

}
