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
    convenience init?(createRequestForServerMessage
        serverMessage: ServerMessage,
        masterKey: NSData,
        lockKey: NSData)
    {
        self.init()
        
        if var
            (randomLock, serverUnlock) = Ed25519.keyPair(),
            unlockRequestSigningKey    = Ed25519.diffieHellmanSharedSecret(secretKey: randomLock, publicKey: lockKey),
            (_, verifyUnlock) = Ed25519.keyPairFromSeed(unlockRequestSigningKey),
            siteHash          = serverMessage.URL.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            siteKeyPair       = Ed25519.keyPairFromSeed(siteHash)
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            let suk = serverUnlock.base64URLString(padding: false)
            let vuk = verifyUnlock.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\ncmd=ident\r\nidk=\(idk)\r\nsuk=\(suk)\r\nvuk=\(vuk)").base64URLEncodedString(padding: false),
                payload     = clientValue.dataUsingEncoding(NSASCIIStringEncoding)?.mutableCopy() as? NSMutableData
            {
                payload.appendData(serverMessage.data)
                
                if let
                    ids = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    url = serverMessage.responseURL
                {
                    let body     = "server=\(serverMessage.string)&client=\(clientValue)&ids=\(ids)"
                    
                    self.URL        = url
                    self.HTTPMethod = "POST"
                    self.HTTPBody   = body.dataUsingEncoding(NSASCIIStringEncoding)
                }
                else { return nil }
            }
            else { return nil }
        }
        else { return nil }
    }
    
    convenience init?(loginRequestForServerMessage
        serverMessage: ServerMessage,
        masterKey: NSData)
    {
        self.init()
        
        if var
            siteHash    = serverMessage.URL.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            siteKeyPair = Ed25519.keyPairFromSeed(siteHash),
            siteURLData = serverMessage.URL.urlData,
            signedURL   = Ed25519.signatureForMessage(siteURLData, secretKey: siteKeyPair.secretKey)
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\ncmd=ident\r\nidk=\(idk)\r\n").base64URLEncodedString(padding: false),
                payload     = clientValue.dataUsingEncoding(NSASCIIStringEncoding)?.mutableCopy() as? NSMutableData
            {
                payload.appendData(serverMessage.data)
                
                if let
                    ids = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    url = serverMessage.responseURL
                {
                    let body = "server=\(serverMessage.string)&client=\(clientValue)&ids=\(ids)"
                    
                    self.URL        = url
                    self.HTTPMethod = "POST"
                    self.HTTPBody   = body.dataUsingEncoding(NSASCIIStringEncoding)
                }
                else { return nil }
            }
            else { return nil }
        }
        else { return nil }
    }
    
    convenience init?(queryForSqrlLink sqrlLink: NSURL, masterKey: NSData)
    {
        self.init()
        
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
                    let body = "server=\(serverValue)&client=\(clientValue)&ids=\(ids)"
                    
                    self.URL        = url
                    self.HTTPMethod = "POST"
                    self.HTTPBody   = body.dataUsingEncoding(NSASCIIStringEncoding)
                }
                else { return nil }
            }
            else { return nil }
        }
        else { return nil }
    }
    
    
}
