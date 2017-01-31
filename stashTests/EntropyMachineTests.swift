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
        
        if let data = stringData.data(using: String.Encoding.utf8) {
            
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
            
            if let data = stringData.data(using: String.Encoding.utf8) {
                for _ in 0...100 {
                    machine.addEntropy(data)
                }
            }
        }
        
        let result1 = entropyMachine.stop()
        if let result2 = entropyMachine2.stop() {
            XCTAssert((result1 == result2) == false, "Hashes are equal when should unquie")
        } else {
            XCTAssert(false, "entropymachine 2 didn't return resulting hash")
        }
    }
    
    func testEntropyMachineReuse() {
        entropyMachine.start()
        let result = entropyMachine.stop()
        
        entropyMachine.start()
        if let result2 = entropyMachine.stop() {
            
            if (result == result2) == false {
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
        let data       = stringData.data(using: String.Encoding.utf8)
        var completedEntropyPush = false
        
        // Dispatch background thread to push data in
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: { () -> Void in
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
        Thread.sleep(forTimeInterval: 1)
        
        if let result = entropyMachine.stop() {
            XCTAssert(true, "Passed Stop() priority")
        }
    }
    
    func testThreadedAccess() {
        var threadGroup = DispatchGroup()
        let stringData  = "some string data"
        let data        = stringData.data(using: String.Encoding.utf8)
        
        entropyMachine.start()
        
        for i in 0...10 {
            threadGroup.enter()
            
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: { () -> Void in
                if (data != nil) {
                    for _ in 0...1_000 {
                        self.entropyMachine.addEntropy(data!)
                    }
                } else {
                    XCTAssert(false, "Unable to create data to push")
                }
                threadGroup.leave()
            })
        }
        threadGroup.wait(timeout: DispatchTime.distantFuture)
        
        if let result = entropyMachine.stop() {
            XCTAssert(true, "Passed Stop() priority")
        }
    }
    
    func testThreadedAccessWhileStillStreamingEntropy() {
        let stringData  = "some string data"
        let data        = stringData.data(using: String.Encoding.utf8)
        
        entropyMachine.start()
        
        for i in 0...10 {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: { () -> Void in
                if (data != nil) {
                    for _ in 0...1_000_000_000 {
                        self.entropyMachine.addEntropy(data!)
                    }
                } else {
                    XCTAssert(false, "Unable to create data to push")
                }
            })
        }
        
        Thread.sleep(forTimeInterval: 5)
        
        if let result = entropyMachine.stop() {
            XCTAssert(true, "Passed Stop() priority")
        }
    }
    
}
