//
//  NSURLSessionTaskSqrl.swift
//  stash
//
//  Created by James Stidard on 14/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

enum SQRLCommand {
    case query, ident, enable, disable
}

extension NSMutableURLRequest
{
    convenience init?(createRequestForServerMessage
        serverMessage: ServerMessage,
        masterKey: Data,
        lockKey: Data)
    {
        self.init()
        
        if var
            (randomLock, serverUnlock) = Ed25519.keyPair(),
            var unlockRequestSigningKey    = Ed25519.diffieHellmanSharedSecret(secretKey: randomLock, publicKey: lockKey),
            var (_, verifyUnlock) = Ed25519.keyPairFromSeed(unlockRequestSigningKey),
            var siteHash          = serverMessage.URL.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            var siteKeyPair       = Ed25519.keyPairFromSeed(siteHash)
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            let suk = serverUnlock.base64URLString(padding: false)
            let vuk = verifyUnlock.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\ncmd=ident\r\nidk=\(idk)\r\nsuk=\(suk)\r\nvuk=\(vuk)").base64URLEncodedString(padding: false),
                var payload     = clientValue.dataUsingEncoding(String.Encoding.ascii)?.mutableCopy() as? NSMutableData
            {
                payload.appendData(serverMessage.data)
                
                if let
                    ids = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    let url = serverMessage.responseURL
                {
                    let body     = "server=\(serverMessage.string)&client=\(clientValue)&ids=\(ids)"
                    
                    self.url        = url as URL
                    self.httpMethod = "POST"
                    self.HTTPBody   = body.dataUsingEncoding(String.Encoding.ascii)
                }
                else { return nil }
            }
            else { return nil }
        }
        else { return nil }
    }
    
    convenience init?(loginRequestForServerMessage
        serverMessage: ServerMessage,
        masterKey: Data)
    {
        self.init()
        
        if var
            siteHash    = serverMessage.URL.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            var siteKeyPair = Ed25519.keyPairFromSeed(siteHash),
            var siteURLData = serverMessage.URL.urlData,
            var signedURL   = Ed25519.signatureForMessage(siteURLData, secretKey: siteKeyPair.secretKey)
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\ncmd=ident\r\nidk=\(idk)\r\n").base64URLEncodedString(padding: false),
                var payload     = clientValue.dataUsingEncoding(String.Encoding.ascii)?.mutableCopy() as? NSMutableData
            {
                payload.appendData(serverMessage.data)
                
                if let
                    ids = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    let url = serverMessage.responseURL
                {
                    let body = "server=\(serverMessage.string)&client=\(clientValue)&ids=\(ids)"
                    
                    self.url        = url as URL
                    self.httpMethod = "POST"
                    self.HTTPBody   = body.dataUsingEncoding(String.Encoding.ascii)
                }
                else { return nil }
            }
            else { return nil }
        }
        else { return nil }
    }
    
    convenience init?(queryForSqrlLink sqrlLink: URL, masterKey: Data)
    {
        self.init()
        
        if var
            siteHash    = sqrlLink.sqrlSiteKeyHash(hashFunction: HmacSha256.hash, masterKey: masterKey),
            var siteKeyPair = Ed25519.keyPairFromSeed(siteHash),
            var siteURLData = sqrlLink.urlData,
            var signedURL   = Ed25519.signatureForMessage(siteURLData, secretKey: siteKeyPair.secretKey),
            var serverValue = sqrlLink.sqrlBase64URLString
        {
            let idk = siteKeyPair.publicKey.base64URLString(padding: false)
            
            if var
                clientValue = String("ver=1\r\nidk=\(idk)\r\ncmd=query\r\n").base64URLEncodedString(padding: false),
                var payload     = clientValue.dataUsingEncoding(String.Encoding.ascii)?.mutableCopy() as? NSMutableData,
                var serverData  = serverValue.data(using: String.Encoding.ascii)
            {
                payload.appendData(serverData)
                if let
                    ids = Ed25519.signatureForMessage(payload, secretKey: siteKeyPair.secretKey)?.base64URLString(padding: false),
                    let url = sqrlLink.sqrlResponseURL
                {
                    let body = "server=\(serverValue)&client=\(clientValue)&ids=\(ids)"
                    
                    self.url        = url
                    self.httpMethod = "POST"
                    self.HTTPBody   = body.dataUsingEncoding(String.Encoding.ascii)
                }
                else { return nil }
            }
            else { return nil }
        }
        else { return nil }
    }
    
    
}
