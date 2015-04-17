//
//  NSURLSessionTaskSqrl.swift
//  stash
//
//  Created by James Stidard on 14/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

enum SQRLCommand {
    case Query, Ident, Enable, Disable
}

extension NSMutableURLRequest
{
    convenience init?(queryForSqrlLink sqrlLink: NSURL, withMasterKey masterKey: NSData)
    {
        self.init()
        if !self.dynamicType.setForQueryURL(&URL, method: &HTTPMethod, body: &HTTPBody, forSqrlLink: sqrlLink, withMasterKey: masterKey) {
            return nil
        }
    }
    
    convenience init?(createIdentForServerURL serverURL: NSURL, serverValue: String, masterKey: NSData, identityLockKey: NSData)
    {
        self.init()
        self.URL = serverURL
        if !self.dynamicType.setForCreationURL(URL: &URL!, method: &HTTPMethod, body: &HTTPBody, withMasterKey: masterKey, identityLockKey: identityLockKey, serverValue: serverValue) {
            return nil
        }
    }
    
    convenience init?(loginIdentForServerURL serverURL: NSURL, serverValue: String, masterKey: NSData)
    {
        self.init()
        self.URL = serverURL
        if !self.dynamicType.setForLoginURL(&URL, method: &HTTPMethod, body: &HTTPBody, serverValue: serverValue, withMasterKey: masterKey) {
            return nil
        }
    }
    
    private class func setForQueryURL(
        inout inoutURL: NSURL?,
        inout method inoutMethod: String,
        inout body inoutBody:NSData?,
        forSqrlLink sqrlLink: NSURL,
        withMasterKey masterKey: NSData) -> Bool
    {
        if var
            siteHash    = sqrlLink.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            siteKeyPair = Ed25519.keyPairFromSeed(siteHash),
            siteURLData = sqrlLink.urlData,
            signedURL   = Ed25519.signatureForMessage(siteURLData, secretKey: siteKeyPair.secretKey),
            serverValue = sqrlLink.sqrlBase64URLString
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\nidk=\(idk)\r\ncmd=query\r\n").base64URLEncodedString(padding: false),
                payload     = clientValue.dataUsingEncoding(NSASCIIStringEncoding)?.mutableCopy() as? NSMutableData,
                serverData  = serverValue.dataUsingEncoding(NSASCIIStringEncoding)
            {
                payload.appendData(serverData)
                if let
                    ids = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    url = sqrlLink.sqrlResponseURL
                {
                    let postBody = "server=\(serverValue)&client=\(clientValue)&ids=\(ids)"
                    
                    inoutURL    = url
                    inoutMethod = "POST"
                    inoutBody   = postBody.dataUsingEncoding(NSASCIIStringEncoding)
                    return true
                }
            }
        }
        return false
    }
    
    private class func setForCreationURL(
        inout URL inoutURL: NSURL,
        inout method inoutMethod: String,
        inout body inoutBody:NSData?,
        withMasterKey masterKey: NSData,
        identityLockKey identityLock: NSData,
        serverValue: String) -> Bool
    {
        if var
            (randomLock, serverUnlock) = Ed25519.keyPair(),
            sharedKey         = Ed25519.diffieHellmanSharedSecret(secretKey: randomLock, publicKey: identityLock),
            (_, verifyUnlock) = Ed25519.keyPairFromSeed(sharedKey),
            siteHash          = inoutURL.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            siteKeyPair       = Ed25519.keyPairFromSeed(siteHash)
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            let suk = serverUnlock.base64URLString(padding: false)
            let vuk = verifyUnlock.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\ncmd=ident\r\nidk=\(idk)\r\nsuk=\(suk)\r\nvuk=\(vuk)").base64URLEncodedString(padding: false),
                payload     = clientValue.dataUsingEncoding(NSASCIIStringEncoding)?.mutableCopy() as? NSMutableData,
                serverData  = serverValue.dataUsingEncoding(NSASCIIStringEncoding)
            {
                payload.appendData(serverData)
                
                if let
                    ids            = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    serverMessages = serverValue.sqrlServerResponse(),
                    newQueryPath   = serverMessages[.Query],
                    url            = inoutURL.urlByReplacingQueryPath(newQueryPath)
                {
                    let postBody = "server=\(serverValue)&client=\(clientValue)&ids=\(ids)"
                    
                    inoutURL    = url
                    inoutMethod = "POST"
                    inoutBody   = postBody.dataUsingEncoding(NSASCIIStringEncoding)
                    return true
                }
            }
        }
        return false
    }
    
    private class func setForLoginURL(
        inout inoutURL: NSURL?,
        inout method inoutMethod: String,
        inout body inoutBody:NSData?,
        serverValue: String,
        withMasterKey masterKey: NSData) -> Bool
    {
        if var
            siteHash    = inoutURL?.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            siteKeyPair = Ed25519.keyPairFromSeed(siteHash),
            siteURLData = inoutURL?.urlData,
            signedURL   = Ed25519.signatureForMessage(siteURLData, secretKey: siteKeyPair.secretKey)
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\ncmd=ident\r\nidk=\(idk)\r\n").base64URLEncodedString(padding: false),
                payload     = clientValue.dataUsingEncoding(NSASCIIStringEncoding)?.mutableCopy() as? NSMutableData,
                serverData  = serverValue.dataUsingEncoding(NSASCIIStringEncoding)
            {
                payload.appendData(serverData)
                if let
                    ids = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    serverMessages = serverValue.sqrlServerResponse(),
                    newQueryPath   = serverMessages[.Query],
                    url            = inoutURL?.urlByReplacingQueryPath(newQueryPath)
                {
                    let postBody = "server=\(serverValue)&client=\(clientValue)&ids=\(ids)"
                    
                    inoutURL    = url
                    inoutMethod = "POST"
                    inoutBody   = postBody.dataUsingEncoding(NSASCIIStringEncoding)
                    return true
                }
            }
        }
        return false
    }
}