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
    func SQRLSession(_ session: URLSession, shouldCreateAccountForServer serverName: String, proceed: (Bool) -> ())
    func SQRLSession(_ session: URLSession, shouldLoginAccountForServer serverName: String, proceed: (Bool) -> ())
    func SQRLSession(_ session: URLSession, succesfullyCompleted success: Bool)
}

extension URLSession
{
    convenience init(
        stashSessionWithdelegate delegate: URLSessionDelegate?,
        configuration: URLSessionConfiguration = URLSessionConfiguration.default)
    {
        configuration.httpAdditionalHeaders = ["User-Agent" : "Stash/1"]
        self.init(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    func sqrlDataTaskForSqrlLink(_ sqrlLink: URL, masterKey: Data, lockKey: Data, delegate: SQRLSessionDelegate) -> URLSessionTask?
    {
        if let request = NSMutableURLRequest(queryForSqrlLink: sqrlLink, masterKey: masterKey)
        {
            return self.sqrlDataTaskWithRequest(request, masterKey: masterKey, lockKey: lockKey, delegate: delegate)
        }
        return nil
    }
    
    fileprivate func sqrlDataTaskWithRequest(
        _ request: URLRequest,
        masterKey: Data,
        lockKey: Data,
        delegate: SQRLSessionDelegate) -> URLSessionDataTask
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
    
    fileprivate func handleServerResponse(
        #data: NSData?,
        _ response: URLResponse?,
        error: NSError?,
        lastCommand: SQRLCommand,
        masterKey: Data,
        lockKey: Data? = nil,
        delegate: SQRLSessionDelegate) -> Void
    {
        if let
            serverMessage = ServerMessage(data: data, response: response),
            let tifRaw        = serverMessage.dictionary[.TIF]?.toInt(),
            let serverName    = serverMessage.dictionary[.ServersFriendlyName],
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
    
    fileprivate func createIdentity(#serverMessage: ServerMessage, _ masterKey: Data, lockKey: Data, delegate: SQRLSessionDelegate)
    {
        if let
            serverName = serverMessage.dictionary[.ServersFriendlyName],
            let request    = NSMutableURLRequest(createRequestForServerMessage: serverMessage, masterKey: masterKey, lockKey: lockKey)
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
    
    fileprivate func loginIdentity(#serverMessage: ServerMessage, _ masterKey: Data, delegate: SQRLSessionDelegate)
    {
        
        if let
            serverName = serverMessage.dictionary[.ServersFriendlyName],
            let request    = NSMutableURLRequest(loginRequestForServerMessage: serverMessage, masterKey: masterKey)
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
