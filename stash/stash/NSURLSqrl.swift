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
    func sqrlSiteKeyString() -> String?
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
    
    
    func sqrlResponseURL() -> NSURL?
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
    
    
    func isValidSqrlLink() -> Bool
    {
        return
            (self.scheme == "sqrl" || self.scheme == "qrl") &&
            self.host != nil &&
            self.query?.lowercaseString.rangeOfString("nut=") != nil
    }
}