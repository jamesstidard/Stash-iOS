//
//  AesGcm.swift
//  stash
//
//  Created by James Stidard on 08/02/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

class AesGcm {
    
    class func encrypt256(inout key: NSData, inout sensitiveData: NSData?, inout additionalData: NSData?, useIV: Bool) -> (cipherData: NSData, tag: NSData)?
    {
        let cipher  = EVP_aes_256_gcm()
        
        
        if (key.length != 256) {
            println("AesGcm.encrypt256 requies a key of 256 bytes")
            return nil
        }
        var keyPtr = UnsafeMutablePointer<UInt8>(key.bytes)
        
        
        var ivData = NSData(bytes: nil, length: 0)
        if useIV {
            let ivSize  = EVP_CIPHER_iv_length(cipher)
            if let randomData = SodiumUtilities.randomBytes(Int(ivSize)) {
                ivData = randomData
            }
        }
        var ivDataPtr = UnsafeMutablePointer<UInt8>(ivData.bytes)
        
        
        var context         = EVP_CIPHER_CTX_new()
        var outLength :CInt = 0
        var outData         = NSMutableData(length: sensitiveData!.length)
        var outDataPtr      = UnsafeMutablePointer<UInt8>(outData!.bytes)
        
        
        // set cipher type and mode. default iv length 96-bits
        if (EVP_EncryptInit_ex(context, cipher, nil, keyPtr, ivDataPtr) == 0) {
            println("AesGcm.encrypt256 unable to initialise encryption")
            return nil
        }
        
        if additionalData != nil
        {
            var additionalDataPtr = UnsafeMutablePointer<UInt8>(additionalData!.bytes)
            
            // add additional data (nil in out to say it's aad)
            if (EVP_EncryptUpdate(context, nil, &outLength, additionalDataPtr, Int32(additionalData!.length)) == 0) {
                println("AesGcm.encrypt256 unable to update encryption with additional data")
                return nil
            }
        }
        
        if sensitiveData != nil
        {
            var sensitivDataPtr = UnsafeMutablePointer<UInt8>(sensitiveData!.bytes)
            
            // encrypt sensitive data
            if (EVP_EncryptUpdate(context, outDataPtr, &outLength, sensitivDataPtr, Int32(sensitiveData!.length)) == 0) {
                println("AesGcm.encrypt256 unable to update encryption with sensitive data")
                return nil
            }
        }
        
        if (EVP_EncryptFinal_ex(context, outDataPtr, &outLength) == 0) {
            println("AesGcm.encrypt256 unable to finalise encryption")
            return nil
        }
        
        var tag = NSMutableData(length: 16)
        var tagPtr = UnsafeMutablePointer<UInt8>(tag!.bytes)
        if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_GET_TAG, Int32(tag!.length), tagPtr) == 0) {
            println("AesGcm.encrypt256 unable to get tag for encrypted data")
            return nil
        }
        
        if (EVP_CIPHER_CTX_cleanup(context) == 0) {
            println("AesGcm.encrypt256 unable to clean up context")
            return nil
        }
        
        
        return (outData!, tag!)
    }
    
    
    class func decrypt256(inout key: NSData, inout cipherData: NSData?, inout additionalData: NSData?, inout iv: NSData?, tag: NSData?) -> Bool
    {
        let cipher  = EVP_aes_256_gcm()
        
        
        if (key.length != 256) {
            println("AesGcm.decrypt256 requies a key of 256 bytes")
            return false
        }
        var keyPtr = UnsafeMutablePointer<UInt8>(key.bytes)
        
        
        var ivPtr :UnsafeMutablePointer<UInt8>!
        if iv == nil {
            ivPtr = UnsafeMutablePointer<UInt8>.alloc(1)
        } else {
            ivPtr = UnsafeMutablePointer<UInt8>(iv!.bytes)
        }
        
        
        let context         = EVP_CIPHER_CTX_new()
        var outLength: CInt = 0
        var cipherLength    = cipherData?.length ?? 0
        let out             = NSMutableData(length: cipherLength)
        var outPtr          = UnsafeMutablePointer<UInt8>(out!.mutableBytes)
        
        
        if (EVP_DecryptInit_ex(context, EVP_aes_256_gcm(), nil, keyPtr, ivPtr) == 0) {
            println("AesGcm.decrypt256 unable to initialise decryption")
            return false
        }
        
        if tag != nil
        {
            var tagPtr = UnsafeMutablePointer<UInt8>(tag!.bytes)
            
            if (EVP_CIPHER_CTX_ctrl(context, EVP_CTRL_GCM_SET_TAG, Int32(tag!.length), tagPtr) == 0) {
                println("AesGcm.decrypt256 not attach AES-GCM tag")
                return false
            }
        }
        
        if additionalData != nil
        {
            var additionalDataPtr = UnsafeMutablePointer<UInt8>(additionalData!.bytes)
            
            if (EVP_DecryptUpdate(context, nil, &outLength, additionalDataPtr, Int32(additionalData!.length)) == 0) {
                println("AesGcm.decrypt256 could not update AES-GCM decryption with additional data")
                return false
            }
        }
        
        if cipherData != nil
        {
            var cipherDataPtr = UnsafeMutablePointer<UInt8>(cipherData!.bytes)
            
            if (EVP_DecryptUpdate(context, outPtr, &outLength, cipherDataPtr, Int32(cipherData!.length)) == 0) {
                println("AesGcm.decrypt256 could not update AES-GCM decryption with cipher data")
                return false
            }
        }
        
        if (EVP_DecryptFinal_ex(context, outPtr, &outLength) <= 0) {
            println("AesGcm.decrypt256 could not verify AES-GCM decryption")
            return false
        }
        
        if (EVP_CIPHER_CTX_cleanup(context) == 0) {
            println("AesGcm.decrypt256 unable to clean up context")
            return false
        }
        
        return true
    }
}