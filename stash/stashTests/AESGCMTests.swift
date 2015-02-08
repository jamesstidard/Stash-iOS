//
//  AESGCMTests.swift
//  stash
//
//  Created by James Stidard on 07/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import XCTest

class AESGCMTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        
        
        // TODO: be 1 block size larger then inlen
        var outLenAad: CInt    = 0
        var outLenCipher: CInt = 0
        var outLenAll: CInt    = 0
        var key: [UInt8]  = [ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
                             16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
        var iv: [UInt8]   = [ 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12]
        
        let string     = "Some Cryto Text this is going to get pretty large up in here. *background vocals* up in here. That's pretty much the best I got so I'm going to result to c+p.Some Cryto Text this is going to get pretty large up in here. *background vocals* up in here. That's pretty much the best I got so I'm going to result to c+p.Some Cryto Text this is going to get pretty large up in here. *background vocals* up in here. That's pretty much the best I got so I'm going to result to c+p.Some Cryto Text this is going to get pretty large up in here. *background vocals* up in here. That's pretty much the best I got so I'm going to result to c+p.Some Cryto Text this is going to get pretty large up in here. *background vocals* up in here. That's pretty much the best I got so I'm going to result to c+p.Some Cryto Text this is going to get pretty large up in here. *background vocals* up in here. That's pretty much the best I got so I'm going to result to c+p."
        var inText     = string.dataUsingEncoding(NSASCIIStringEncoding)
        var inTextPtr  = UnsafeMutablePointer<UInt8>(inText!.bytes)
        let additional = "Some additional data Some additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional dataSome additional data"
        var aad        = additional.dataUsingEncoding(NSASCIIStringEncoding)
        var aadPtr     = UnsafeMutablePointer<UInt8>(aad!.bytes)
        let outBuf = NSMutableData(length: inText!.length)
        var outPtr = UnsafeMutablePointer<UInt8>(outBuf!.bytes)
        
        var context = EVP_CIPHER_CTX_new()
        
        // set cipher type and mode. default iv length 96-bits
        if (EVP_EncryptInit_ex(context, EVP_aes_256_gcm(), nil, &key, &iv) == 0) {
            XCTAssertTrue(false, "Could not initialise AES-GCM encryption")
        }
        
        // add additional data (nil in out to say it's aad)
        if (EVP_EncryptUpdate(context, nil, &outLenAad, aadPtr, Int32(aad!.length)) == 0) {
            XCTAssertTrue(false, "Could not update AES-GCM encryption")
        }
        
        // encrypt in text
        if (EVP_EncryptUpdate(context, outPtr, &outLenCipher, inTextPtr, Int32(inText!.length)) == 0) {
            XCTAssertTrue(false, "Could not update AES-GCM encryption")
        }
        
        if (EVP_EncryptFinal_ex(context, outPtr, &outLenCipher) == 0) {
            XCTAssertTrue(false, "Could not finalise AES-GCM encryption")
        }
        
        var tag = NSMutableData(length: 16)
        var tagPtr = UnsafeMutablePointer<UInt8>(tag!.bytes)
        if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_GET_TAG, Int32(tag!.length), tagPtr) == 0) {
            XCTAssertTrue(false, "Could not get tag")
        }
        if (EVP_CIPHER_CTX_cleanup(context) == 0) {
            XCTAssertTrue(false, "Could not clean up context after encryption")
        }
        
        // decrypt
        let decryptOut    = NSMutableData(length: outBuf!.length)
        var decryptOutPtr = UnsafeMutablePointer<UInt8>(outBuf!.mutableBytes)
        context           = EVP_CIPHER_CTX_new()

        var decryptOutLen: CInt = 0
        var decryptedPlainTextLen: CInt = 0

        if (EVP_DecryptInit_ex(context, EVP_aes_256_gcm(), nil, &key, &iv) == 0) {
            XCTAssertTrue(false, "Could not init AES-GCM decryption")
        }
        
        if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_SET_TAG, Int32(tag!.length), tagPtr) == 0) {
            XCTAssertTrue(false, "Could not attach AES-GCM tag")
        }

        if (EVP_DecryptUpdate(context, nil, &decryptOutLen, aadPtr, Int32(aad!.length)) == 0) {
            XCTAssertTrue(false, "Could not update AES-GCM decryption with aad")
        }
        
        if (EVP_DecryptUpdate(context, decryptOutPtr, &decryptOutLen, outPtr, Int32(outBuf!.length)) == 0) {
            XCTAssertTrue(false, "Could not update AES-GCM decryption with cipher text")
        }
        decryptedPlainTextLen = decryptOutLen
//        decryptOutPtr = decryptOutPtr + Int(decryptOutLen)
        
        if (EVP_DecryptFinal_ex(context, decryptOutPtr, &decryptOutLen) <= 0) {
            XCTAssertTrue(false, "Could not verify AES-GCM decryption")
        }
        
        EVP_CIPHER_CTX_free(context)
        
        
    }

}
