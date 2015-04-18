//
//  NSURLSqrl.swift
//  stash
//
//  Created by James Stidard on 12/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension NSURL
{
    var urlData: NSData? {
        return self.absoluteString?.dataUsingEncoding(NSASCIIStringEncoding)
    }
    
    var sqrlResponseURL: NSURL?
        {
            if var
                components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false),
                scheme     = self.scheme?.lowercaseString
                where
                scheme == "sqrl" || scheme == "qrl"
            {
                // strip url of superfluous info
                components.user     = nil
                components.password = nil
                components.port     = nil
                
                // compose sqrl response url
                components.scheme = (scheme == "sqrl") ? "https" : "http"
                components.host   = components.host?.lowercaseString
                
                return components.URL
            }
            
            return nil
    }
    
    
    var sqrlSiteKeyString: String?
    {
        if self.host == nil { return nil } // The service has got to atleast have a domain, right?
        
        
        var siteKeyString = self.host!.lowercaseString
        
        // is if the service has asked to extend the key to include any of the path
        // Use the first extention ('d') specified - if multiple are given for some reason...
        if let
            components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false),
            queryItems = components.queryItems as? [NSURLQueryItem],
            extention  = queryItems.filter({$0.name == "d"}).first?.value?.toInt()
        {
            // If the service asks for extention and there is no path
            // or the extention is longer then the path - get out of here; this isn't valid
            if (path == nil || extention > count(path!)) { return nil }
                
            // Otherwise lets get the extention string with Swift's nasty syntax
            siteKeyString += path!.substringWithRange(Range(start: path!.startIndex, end: advance(path!.startIndex, extention)))
        }
            
        return siteKeyString
    }
    
    var sqrlBase64URLString: String?
    {
            return self.absoluteString?.base64URLEncodedString(padding: false)
    }
    
    
    var isValidSqrlLink: Bool
        {
            return
                (self.scheme == "sqrl" || self.scheme == "qrl") &&
                    self.host != nil &&
                    self.query?.lowercaseString.rangeOfString("nut=") != nil
    }
    
    func urlByReplacingQueryPath(pathWithQuery: String) -> NSURL?
    {
        if var
            components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)
        {
            let parts = split(pathWithQuery, maxSplit: 1, allowEmptySlices: false) { $0 == "?" }
            
            // compose sqrl response url
            components.path  = (parts.count > 0) ? parts[0] : nil
            components.query = (parts.count > 1) ? parts[1] : components.query
                
            return components.URL
        }
            
        return nil
    }
    
    func sqrlSiteKeyHash(hashFunction hash: (message: NSData, key: NSData) -> NSData?, masterKey: NSData) -> NSData?
    {
        if let siteKeyData = self.sqrlSiteKeyString?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return hash(message: siteKeyData, key: masterKey)
        }
        return nil
    }
}