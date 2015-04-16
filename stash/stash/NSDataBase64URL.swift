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
    func base64URLString() -> String
    {
        return self.base64String()
                   .stringByReplacingOccurrencesOfString("+", withString: "-")
                   .stringByReplacingOccurrencesOfString("/", withString: "_")
    }
    
    func base64URLString(#padding: Bool) -> String
    {
        var string       = self.base64URLString()
        return (padding) ? string : string.stringByReplacingOccurrencesOfString("=", withString: "")
    }
}