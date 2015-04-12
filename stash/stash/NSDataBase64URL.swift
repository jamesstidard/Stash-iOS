//
//  NSDataBase64URL.swift
//  stash
//
//  Created by James Stidard on 12/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension NSData
{
    func base64URLEncodedStringWithOptions(options: NSDataBase64EncodingOptions) -> String
    {
        return self.base64EncodedStringWithOptions(options)
                   .stringByReplacingOccurrencesOfString("+", withString: "-")
                   .stringByReplacingOccurrencesOfString("/", withString: "_")
    }
    
    func base64URLEncodedStringWithOptions(options: NSDataBase64EncodingOptions, padding: Bool) -> String
    {
        var string       = self.base64URLEncodedStringWithOptions(options)
        return (padding) ? string : string.stringByReplacingOccurrencesOfString("=", withString: "")
    }
}