//
//  AESGCMTests.swift
//  stash
//
//  Created by James Stidard on 07/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import XCTest

class AESGCMTests: XCTestCase {
    
    lazy var testEncryptionVectorFile: NSString? = {
        let bundle = NSBundle(forClass: AESGCMTests.self)
        
        if let path = bundle.pathForResource("gcmEncryptExtIV256", ofType: "rsp") {
            if let url = NSURL(fileURLWithPath: path) {
                return NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding, error: nil)
            }
        }
        return nil
    }()
    
    lazy var testDecryptionVectorFile: NSString? = {
        let bundle = NSBundle(forClass: AESGCMTests.self)
        
        if let path = bundle.pathForResource("gcmDecrypt256", ofType: "rsp") {
            if let url = NSURL(fileURLWithPath: path) {
                return NSString(contentsOfURL: url, encoding: NSASCIIStringEncoding, error: nil)
            }
        }
        return nil
    }()
    
    class Configuration {
        var index                = 0
        var keyLength            = 0
        var ivLength             = 0
        var plainTextLength      = 0
        var additionalDataLength = 0
        var tagLength            = 0
        
        var vectors = [TestVector]()
    }
    
    class TestVector {
        var index                   = 0
        var key: NSData?            = nil
        var iv: NSData?             = nil
        var plainText: NSData?      = nil
        var additionalData: NSData? = nil
        var cipherText: NSData?     = nil
        var tag: NSData?            = nil
        var shouldPass: Bool        = true
    }
    
    enum BlockType: Int {
        case ConfigurationBlock
        case TestVectorBlock
        case None
    }
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        OpenSSLUtilities.initialiseCryptoLibrary()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    

    
    func testRunEncryptionVectors() {
        
        if let tests = AESGCMTests.createTestObjectsFromTextFile(testEncryptionVectorFile!) {
            for configuration in tests {
                for vector in configuration.vectors {
                    
                    // encrypt
                    if let result = AesGcm.encrypt256(&vector.key!, sensitiveData: &vector.plainText, additionalData: vector.additionalData, iv: &vector.iv, tagByteLength: configuration.tagLength/8) {
                        
                        // test tag output
                        if vector.tag != nil && result.tag != nil {
                            XCTAssertTrue(vector.tag!.isEqualToData(result.tag!), "AES-GCM encryption test vector failed to produce the wrong tag configutation \(configuration.index) vector \(vector.index)")
                        } else if vector.tag != nil && result.tag == nil{
                            XCTAssertTrue(false, "AES-GCM encryption test vector failed to produce a tag configutation \(configuration.index) vector \(vector.index)")
                        }
                        
                        // test cipher text output
                        if vector.cipherText != nil && result.cipherData != nil {
                            XCTAssertTrue(vector.cipherText!.isEqualToData(result.cipherData!), "AES-GCM encryption test vector failed to produce the wrong cipher data configutation \(configuration.index) vector \(vector.index)")
                        } else if vector.cipherText != nil && result.cipherData == nil{
                            XCTAssertTrue(false, "AES-GCM encryption test vector failed to produce cipher data configutation \(configuration.index) vector \(vector.index)")
                        }
                        
                    } else {
                        XCTAssertTrue(false, "AES-GCM encryption test vector failed getting result for configutation \(configuration.index) vector \(vector.index)")
                    }
                }
            }
        } else {
            XCTAssertTrue(false, "AES-GCM Tests unable to open encryption test vectors")
        }
    }
    
    func testRunDecryptionVectors() {
        
        if let tests = AESGCMTests.createTestObjectsFromTextFile(testDecryptionVectorFile!) {
            for configuration in tests {
                for vector in configuration.vectors {
                    
                    // encrypt
                    if AesGcm.decrypt256(&vector.key!, cipherData: &vector.cipherText, additionalData: &vector.additionalData, iv: &vector.iv, tag: vector.tag) {
                        
                        // Make sure if should have passed
                        XCTAssertTrue(vector.shouldPass == true, "AES-GCM encryption test vector shouldn't have decrypted configutation \(configuration.index) vector \(vector.index)")
                        
                        // test plain text output
                        if vector.plainText != nil && vector.cipherText != nil {
                            XCTAssertTrue(vector.plainText!.isEqualToData(vector.cipherText!), "AES-GCM encryption test vector failed to produce the correct plain text configutation \(configuration.index) vector \(vector.index)")
                        } else if vector.plainText != nil && vector.cipherText == nil{
                            XCTAssertTrue(false, "AES-GCM encryption test vector failed to produce plain text configutation \(configuration.index) vector \(vector.index)")
                        }
                        
                    } else {
                        XCTAssertTrue(vector.shouldPass == false, "AES-GCM encryption test vector failed getting decryption for configutation \(configuration.index) vector \(vector.index)")
                    }
                }
            }
        } else {
            XCTAssertTrue(false, "AES-GCM Tests unable to open decryption test vectors")
        }
    }
    
    class func createTestObjectsFromTextFile(var text: NSString) -> [Configuration]? {
        text = text.stringByReplacingOccurrencesOfString("[", withString: "")
        text = text.stringByReplacingOccurrencesOfString("]", withString: "")
        
        if var lines = text.componentsSeparatedByString("\r\n") as? [String] {
            
            var tests         = [Configuration]()
            var currentConfig = Configuration()
            var currentVector = TestVector()
            var blockType     = BlockType.None
            var lastBlockType = BlockType.None
            
            for line in lines {
                let components = line.componentsSeparatedByString(" ") as [String]
                
                switch(components[0]) {
                case "Keylen":
                    currentConfig.keyLength            = components[2].toInt()!
                    blockType                          = .ConfigurationBlock
                case "IVlen":
                    currentConfig.ivLength             = components[2].toInt()!
                    blockType                          = .ConfigurationBlock
                case "PTlen":
                    currentConfig.plainTextLength      = components[2].toInt()!
                    blockType                          = .ConfigurationBlock
                case "AADlen":
                    currentConfig.additionalDataLength = components[2].toInt()!
                    blockType                          = .ConfigurationBlock
                case "Taglen":
                    currentConfig.tagLength            = components[2].toInt()!
                    blockType                          = .ConfigurationBlock
                    
                case "Count":
                    currentVector.index          = components[2].toInt()!
                    blockType                    = .TestVectorBlock
                case "Key":
                    currentVector.key            = components[2].dataFromHexadecimalString()
                    blockType                    = .TestVectorBlock
                case "IV":
                    currentVector.iv             = components[2].dataFromHexadecimalString()
                    blockType                    = .TestVectorBlock
                case "PT":
                    currentVector.plainText      = components[2].dataFromHexadecimalString()
                    blockType                    = .TestVectorBlock
                case "AAD":
                    currentVector.additionalData = components[2].dataFromHexadecimalString()
                    blockType                    = .TestVectorBlock
                case "CT":
                    currentVector.cipherText     = components[2].dataFromHexadecimalString()
                    blockType                    = .TestVectorBlock
                case "Tag":
                    currentVector.tag            = components[2].dataFromHexadecimalString()
                    blockType                    = .TestVectorBlock
                case "FAIL":
                    currentVector.shouldPass     = false
                    blockType                    = .TestVectorBlock
                    
                default:
                    blockType = .None
                }
                
                if blockType == .None {
                    if lastBlockType == .ConfigurationBlock {
                        currentConfig.index = tests.count
                        tests.append(currentConfig)
                        currentConfig = Configuration()
                    }
                    if lastBlockType == .TestVectorBlock {
                        tests.last?.vectors.append(currentVector)
                        currentVector = TestVector()
                    }
                }
                
                lastBlockType = blockType
            }
            
            return tests
        }
        
        return nil
    }
}
