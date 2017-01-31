//
//  AesGcm.swift
//  stash
//
//  Created by James Stidard on 08/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

class AesGcm {
    
    class func encrypt256( key: inout NSData, sensitiveData posibleSensitiveData: inout NSData?, var additionalData posibleAdditionalData: NSData?, iv posibleIv: inout NSData?, tagByteLength: Int) -> (cipherData: NSData?, tag: NSData?)?
    {
        let cipher  = EVP_aes_256_gcm()
        
        
        if (key.length > 256) {
            print("AesGcm.encrypt256 requies a key of 256 bytes or less")
            return nil
        }
        var keyPtr = UnsafeMutablePointer<UInt8>(key.bytes)
        
        
        var context         = EVP_CIPHER_CTX_new()
        var outLength: CInt = 0
        let cipherLength    = posibleSensitiveData?.length ?? 0
        var cipherData      = NSMutableData(length: cipherLength)
        var cipherDataPtr   = UnsafeMutablePointer<UInt8>(cipherData!.bytes)
        
        
        // set cipher type and mode
        if (EVP_EncryptInit_ex(context, cipher, nil, keyPtr, nil) == 0) {
            print("AesGcm.encrypt256 unable to initialise encryption with Cipter and key")
            return nil
        }
        
        // set IV, if one
        if posibleIv == nil {
            posibleIv = NSMutableData(length: 12)
        }
        
        if let iv = posibleIv
        {
            // Set iv length to size of iv input
            if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_SET_IVLEN, Int32(iv.length), nil) == 0) {
                print("AesGcm.encrypt256 unable to initialise encryption with IV")
                return nil
            }
            
            var ivPtr = UnsafeMutablePointer<UInt8>(iv.bytes)
            if (EVP_EncryptInit_ex(context, nil, nil, nil, ivPtr) == 0) {
                print("AesGcm.encrypt256 unable to initialise encryption with IV")
                return nil
            }
        }
        
        if let additionalData = posibleAdditionalData
        {
            var additionalDataPtr = UnsafeMutablePointer<UInt8>(additionalData.bytes)
            
            // add additional data (nil in out to say it's aad)
            if (EVP_EncryptUpdate(context, nil, &outLength, additionalDataPtr, Int32(additionalData.length)) == 0) {
                print("AesGcm.encrypt256 unable to update encryption with additional data")
                return nil
            }
        }
        
        if let sensitiveData = posibleSensitiveData
        {
            var sensitivDataPtr = UnsafeMutablePointer<UInt8>(sensitiveData.bytes)
            
            // encrypt sensitive data
            if (EVP_EncryptUpdate(context, cipherDataPtr, &outLength, sensitivDataPtr, Int32(sensitiveData.length)) == 0) {
                print("AesGcm.encrypt256 unable to update encryption with sensitive data")
                return nil
            }
        }
        
        if (EVP_EncryptFinal_ex(context, cipherDataPtr, &outLength) == 0) {
            print("AesGcm.encrypt256 unable to finalise encryption")
            return nil
        }
        
        var tag = NSMutableData(length: tagByteLength)
        var tagPtr = UnsafeMutablePointer<UInt8>(tag!.bytes)
        if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_GET_TAG, Int32(tag!.length), tagPtr) == 0) {
            print("AesGcm.encrypt256 unable to get tag for encrypted data")
            return nil
        }
        
        if (EVP_CIPHER_CTX_cleanup(context) == 0) {
            print("AesGcm.encrypt256 unable to clean up context")
            return nil
        }
        
        
        return (cipherData, tag)
    }
    
    
    class func decrypt256( key: inout NSData, cipherData posibleCipherData: inout NSData?, additionalData posibleAdditionalData: inout NSData?, iv posibleIv: inout NSData?, tag posibleTag: NSData?) -> Bool
    {
        let cipher  = EVP_aes_256_gcm()
        
        
        if (key.length > 256) {
            print("AesGcm.decrypt256 requies a key of 256 bytes")
            return false
        }
        var keyPtr = UnsafeMutablePointer<UInt8>(key.bytes)
        
        
        let context         = EVP_CIPHER_CTX_new()
        var outLength: CInt = 0
        var cipherLength    = posibleCipherData?.length ?? 0
        var out             = posibleCipherData?.mutableCopy() as! NSMutableData
        var outPtr          = UnsafeMutablePointer<UInt8>(out.mutableBytes)
        
        
        if (EVP_DecryptInit_ex(context, EVP_aes_256_gcm(), nil, keyPtr, nil) == 0) {
            print("AesGcm.decrypt256 unable to initialise decryption")
            return false
        }
        
        // set IV, if one
        if let iv = posibleIv
        {
            // Set iv length to size of iv input
            if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_SET_IVLEN, Int32(iv.length), nil) == 0) {
                print("AesGcm.encrypt256 unable to initialise encryption with IV")
                return false
            }
            
            var ivPtr = UnsafeMutablePointer<UInt8>(iv.bytes)
            if (EVP_DecryptInit_ex(context, nil, nil, nil, ivPtr) == 0) {
                print("AesGcm.encrypt256 unable to initialise encryption with IV")
                return false
            }
        }
        
        if let tag = posibleTag
        {
            var tagPtr = UnsafeMutablePointer<UInt8>(tag.bytes)
            
            if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_SET_TAG, Int32(tag.length), tagPtr) == 0) {
                print("AesGcm.decrypt256 not attach AES-GCM tag")
                return false
            }
        }
        
        if let additionalData = posibleAdditionalData
        {
            var additionalDataPtr = UnsafeMutablePointer<UInt8>(additionalData.bytes)
            
            if (EVP_DecryptUpdate(context, nil, &outLength, additionalDataPtr, Int32(additionalData.length)) == 0) {
                print("AesGcm.decrypt256 could not update AES-GCM decryption with additional data")
                return false
            }
        }
        
        if let cipherData = posibleCipherData
        {
            var cipherDataPtr = UnsafeMutablePointer<UInt8>(cipherData.bytes)
            
            if (EVP_DecryptUpdate(context, outPtr, &outLength, cipherDataPtr, Int32(cipherData.length)) == 0) {
                print("AesGcm.decrypt256 could not update AES-GCM decryption with cipher data")
                return false
            }
        }
        
        if (EVP_DecryptFinal_ex(context, outPtr, &outLength) <= 0) {
            return false
        }
        
        if (EVP_CIPHER_CTX_cleanup(context) == 0) {
            print("AesGcm.decrypt256 unable to clean up context")
            return false
        }
        
        posibleCipherData = out
        
        return true
    }
}
