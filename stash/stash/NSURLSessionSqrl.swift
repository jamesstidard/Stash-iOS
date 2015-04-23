//
//  NSURLSessionSqrl.swift
//  stash
//
//  Created by James Stidard on 20/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

protocol SQRLSessionDelegate
{
    func SQRLSession(session: NSURLSession, shouldCreateAccountForServer serverName: String, proceed: Bool -> ())
    func SQRLSession(session: NSURLSession, shouldLoginAccountForServer serverName: String, proceed: Bool -> ())
    func SQRLSession(session: NSURLSession, succesfullyCompleted success: Bool)
}

extension NSURLSession
{
    convenience init(
        stashSessionWithdelegate delegate: NSURLSessionDelegate?,
        configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration())
    {
        configuration.HTTPAdditionalHeaders = ["User-Agent" : "Stash/1"]
        self.init(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    func sqrlDataTaskForSqrlLink(sqrlLink: NSURL, masterKey: NSData, lockKey: NSData, delegate: SQRLSessionDelegate) -> NSURLSessionTask?
    {
        if let request = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
        {
            return self.sqrlDataTaskWithRequest(request, masterKey: masterKey, lockKey: lockKey, delegate: delegate)
        }
        return nil
    }
    
    private func sqrlDataTaskWithRequest(
        request: NSURLRequest,
        masterKey: NSData,
        lockKey: NSData,
        delegate: SQRLSessionDelegate) -> NSURLSessionDataTask
    {
        return self.dataTaskWithRequest(request) {
            self.handleServerResponse(
                data: $0,
                response: $1,
                error: $2,
                lastCommand: .Query,
                masterKey: masterKey,
                lockKey: lockKey,
                delegate: delegate)
        }
    }
    
    private func handleServerResponse(
        #data: NSData?,
        response: NSURLResponse?,
        error: NSError?,
        lastCommand: SQRLCommand,
        masterKey: NSData,
        lockKey: NSData? = nil,
        delegate: SQRLSessionDelegate) -> Void
    {
        if let
            serverMessage = ServerMessage(data: data, response: response),
            tifRaw        = serverMessage.dictionary[.TIF]?.toInt(),
            serverName    = serverMessage.dictionary[.ServersFriendlyName]
        where
            tifRaw > 0
        {
            let tif = TIF(UInt(tifRaw))
            
            // If NO current id or previous id on the server AND we didn't just create
            if tif & (.CurrentIDMatch | .PreviousIDMatch) == nil && lastCommand != .Ident && lockKey != nil  {
                self.createIdentity(serverMessage: serverMessage, masterKey: masterKey, lockKey: lockKey!, delegate: delegate)
            }
                
                // if current id exists and we havn't just performed a login
            else if tif & .CurrentIDMatch && lastCommand != .Ident {
                self.loginIdentity(serverMessage: serverMessage, masterKey: masterKey, delegate: delegate)
            }
                
            else {
                delegate.SQRLSession(self, succesfullyCompleted: (error == nil))
            }
        }
        else {
            delegate.SQRLSession(self, succesfullyCompleted: false)
        }
    }
    
    private func createIdentity(#serverMessage: ServerMessage, masterKey: NSData, lockKey: NSData, delegate: SQRLSessionDelegate)
    {
        if let
            serverName = serverMessage.dictionary[.ServersFriendlyName],
            request    = NSMutableURLRequest(createRequestForServerMessage: serverMessage, masterKey: masterKey, lockKey: lockKey)
        {
            delegate.SQRLSession(self, shouldCreateAccountForServer: serverName) { proceed in
                if proceed
                {
                    self.dataTaskWithRequest(request) {
                        self.handleServerResponse(
                            data: $0,
                            response: $1,
                            error: $2,
                            lastCommand: .Ident,
                            masterKey: masterKey,
                            delegate: delegate)
                    }.resume()
                }
            }
        }
    }
    
    private func loginIdentity(#serverMessage: ServerMessage, masterKey: NSData, delegate: SQRLSessionDelegate)
    {
        
        if let
            serverName = serverMessage.dictionary[.ServersFriendlyName],
            request    = NSMutableURLRequest(loginRequestForServerMessage: serverMessage, masterKey: masterKey)
        {
            delegate.SQRLSession(self, shouldLoginAccountForServer: serverName) { proceed in
                if proceed
                {
                    self.dataTaskWithRequest(request) {
                        self.handleServerResponse(
                            data: $0,
                            response: $1,
                            error: $2,
                            lastCommand: .Ident,
                            masterKey: masterKey,
                            delegate: delegate)
                    }.resume()
                }
            }
        }
    }
}