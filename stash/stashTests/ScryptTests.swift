//
//  ScryptTests.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import UIKit
import XCTest

class ScryptTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        SodiumUtilities.initialiseSodium()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEnscrypt() {
        
        let password = "passsord"
        let iterations = 100
        
       // let password = password.dataUsingEncoding(UTF8, allowLossyConversion: false)
        // check for nil notat end of string and add nil terminator char
        
        
        if var finalOut = NSMutableData(length: Int(32)) {
            if var out = NSMutableData(length: Int(32)) {
                if var salt = NSMutableData(length: 0) {
                    
                    var finalOutPtr = UnsafeMutablePointer<UInt8>(finalOut.bytes)
                    var outPtr = UnsafeMutablePointer<UInt8>(out.bytes)
                    var saltPtr = UnsafeMutablePointer<UInt8>(salt.bytes)
                    
                    for i in 1...iterations {
                        crypto_pwhash_scryptsalsa208sha256_ll(nil, UInt(0), saltPtr, UInt(salt.length), UInt64(512), UInt32(256), UInt32(1), outPtr, UInt(out.length))
                        
                        salt = out.mutableCopy() as NSMutableData
                        saltPtr = UnsafeMutablePointer<UInt8>(salt.bytes)
                        
                        if i != 1 {
                            for byte in 0..<finalOut.length {
                                finalOutPtr[byte] = finalOutPtr[byte] ^ outPtr[byte]
                            }
                        } else {
                            finalOut = out.mutableCopy() as NSMutableData
                            finalOutPtr = UnsafeMutablePointer<UInt8>(finalOut.bytes)
                        }
                    }
                }
            }
            println(finalOut)
        }
    }
    
    func testXor() {
        var bytes1 = [0b11111111, 0b11110000] as [UInt8]
        var bytes2 = [0b00001001, 0b11111110] as [UInt8]
        
        var data1  = NSMutableData(bytes: bytes1, length: 2)
        var data2  = NSMutableData(bytes: bytes2, length: 2)
        var result = NSMutableData(length: 2)
        
        var dataPtr1 = UnsafeMutablePointer<UInt8>(data1.mutableBytes)
        var dataPtr2 = UnsafeMutablePointer<UInt8>(data2.mutableBytes)
        var resultPtr = UnsafeMutablePointer<UInt8>(result!.mutableBytes)
        
        for i in 0..<data1.length {
            resultPtr[i] = dataPtr1[i] ^ dataPtr2[i]
        }
        
        println(result)
    }
    
    func testScrypt() {
        
        
        let out = Scrypt.salsa208Sha256(nil, salt: nil, N: UInt64(512), r: UInt32(256), p: UInt32(1))
    }
    
    func testEnScrypt() {
        let password = "password"
        let passwordData = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let saltData = NSMutableData(length: 32)
        
        println(EnScrypt.salsa208Sha256(passwordData, salt: saltData, N: UInt64(512), r: UInt32(256), p: UInt32(1), i: 123))
    }

}
