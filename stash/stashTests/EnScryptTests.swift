//
//  EnScryptTests.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Cocoa
import XCTest

class EnScryptTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        SodiumUtilities.initialiseSodium()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEnScryptPasswordNilSaltNilN512r256p1i1() {
        let expectedOut :[UInt8] = [
            0xa8, 0xea, 0x62, 0xa6, 0xe1, 0xbf, 0xd2, 0x0e,
            0x42, 0x75, 0x01, 0x15, 0x95, 0x30, 0x7a, 0xa3,
            0x02, 0x64, 0x5c, 0x18, 0x01, 0x60, 0x0e, 0xf5,
            0xcd, 0x79, 0xbf, 0x9d, 0x88, 0x4d, 0x91, 0x1c
        ]
        let expectedOutData = NSData(bytes: expectedOut, length: expectedOut.count)
        
        if let actualOutData = EnScrypt.salsa208Sha256(nil, salt: nil, N: UInt64(512), r: UInt32(256), p: UInt32(1), i: 1) {
            
            if expectedOutData.isEqualToData(actualOutData) {
                XCTAssertTrue(true, "Pass")
                return
            }
        }
        
        XCTAssertTrue(false, "EnScrypt.salsa208Sha256 returning incorrect data")
    }
    
    func testEnScryptPasswordNilSaltNilN512r256p1i100() {
        let expectedOut :[UInt8] = [
            0x45, 0xa4, 0x2a, 0x01, 0x70, 0x9a, 0x00, 0x12,
            0xa3, 0x7b, 0x7b, 0x68, 0x74, 0xcf, 0x16, 0x62,
            0x35, 0x43, 0x40, 0x9d, 0x19, 0xe7, 0x74, 0x0e,
            0xd9, 0x67, 0x41, 0xd2, 0xe9, 0x9a, 0xab, 0x67
        ]
        let expectedOutData = NSData(bytes: expectedOut, length: expectedOut.count)
        
        if let actualOutData = EnScrypt.salsa208Sha256(nil, salt: nil, N: UInt64(512), r: UInt32(256), p: UInt32(1), i: 100) {
            
            if expectedOutData.isEqualToData(actualOutData) {
                XCTAssertTrue(true, "Pass")
                return
            }
        }
        
        XCTAssertTrue(false, "EnScrypt.salsa208Sha256 returning incorrect data")
    }
    
    func testEnScryptPasswordNilSaltNilN512r256p1i1000() {
        let expectedOut :[UInt8] = [
            0x3f, 0x67, 0x1a, 0xdf, 0x47, 0xd2, 0xb1, 0x74,
            0x4b, 0x1b, 0xf9, 0xb5, 0x02, 0x48, 0xcc, 0x71,
            0xf2, 0xa5, 0x8e, 0x8d, 0x2b, 0x43, 0xc7, 0x6e,
            0xdb, 0x1d, 0x2a, 0x2c, 0x20, 0x09, 0x07, 0xf5
        ]
        let expectedOutData = NSData(bytes: expectedOut, length: expectedOut.count)
        
        if let actualOutData = EnScrypt.salsa208Sha256(nil, salt: nil, N: UInt64(512), r: UInt32(256), p: UInt32(1), i: 1000) {
            
            if expectedOutData.isEqualToData(actualOutData) {
                XCTAssertTrue(true, "Pass")
                return
            }
        }
        
        XCTAssertTrue(false, "EnScrypt.salsa208Sha256 returning incorrect data")
    }
    
    func testEnScryptPasswordPasswordSaltNilN512r256p1i123() {
        let expectedOut :[UInt8] = [
            0x12, 0x9d, 0x96, 0xd1, 0xe7, 0x35, 0x61, 0x85,
            0x17, 0x25, 0x94, 0x16, 0xa6, 0x05, 0xbe, 0x70,
            0x94, 0xc2, 0x85, 0x6a, 0x53, 0xc1, 0x4e, 0xf7,
            0xd4, 0xe4, 0xba, 0x8e, 0x4e, 0xa3, 0x6a, 0xeb
        ]
        let expectedOutData = NSData(bytes: expectedOut, length: expectedOut.count)
        let password        = "password"
        let passwordData    = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        
        if let actualOutData = EnScrypt.salsa208Sha256(passwordData, salt: nil, N: UInt64(512), r: UInt32(256), p: UInt32(1), i: 123) {
            
            if expectedOutData.isEqualToData(actualOutData) {
                XCTAssertTrue(true, "Pass")
                return
            }
        }
        
        XCTAssertTrue(false, "EnScrypt.salsa208Sha256 returning incorrect data")
    }
    
    func testEnScryptPasswordPasswordSaltZeroedN512r256p1i123() {
        let expectedOut :[UInt8] = [
            0x2f, 0x30, 0xb9, 0xd4, 0xe5, 0xc4, 0x80, 0x56,
            0x17, 0x7f, 0xf9, 0x0a, 0x6c, 0xc9, 0xda, 0x04,
            0xb6, 0x48, 0xa7, 0xe8, 0x45, 0x1d, 0xfa, 0x60,
            0xda, 0x56, 0xc1, 0x48, 0x18, 0x7f, 0x6a, 0x7d
        ]
        let expectedOutData = NSData(bytes: expectedOut, length: expectedOut.count)
        let password        = "password"
        let passwordData    = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let saltData        = NSMutableData(length: 32)
        
        
        if let actualOutData = EnScrypt.salsa208Sha256(passwordData, salt: saltData, N: UInt64(512), r: UInt32(256), p: UInt32(1), i: 123) {
            
            if expectedOutData.isEqualToData(actualOutData) {
                XCTAssertTrue(true, "Pass")
                return
            }
        }
        
        XCTAssertTrue(false, "EnScrypt.salsa208Sha256 returning incorrect data")
    }
}
