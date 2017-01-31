//
//  NSDataBase64URL.swift
//  stash
//
//  Created by James Stidard on 12/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension Data
{
    func base64URLString() -> String
    {
        return (self as NSData).base64String()
                   .replacingOccurrences(of: "+", with: "-")
                   .replacingOccurrences(of: "/", with: "_")
    }
    
    func base64URLString(#padding: Bool) -> String
    {
        var string       = self.base64URLString()
        return (padding) ? string : string.stringByReplacingOccurrencesOfString("=", withString: "")
    }
}
