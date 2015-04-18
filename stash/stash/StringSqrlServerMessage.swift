//
//  StringSqrlServerMessage.swift
//  stash
//
//  Created by James Stidard on 16/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension String
{
    func sqrlServerValueDictionary() -> [SqrlServerResponseKey:String]?
    {
        // Remove the server key if response has one
        var workingCopy = self
        if workingCopy.hasPrefix("server=") {
            let range = self.startIndex ..< advance(workingCopy.startIndex, +7)
            workingCopy.removeRange(range)
        }
        
        // Convert value from base64url encoded to utf8 and find key value pairs within
        workingCopy    = String(fromBase64URLString: workingCopy)
        var dictionary = [SqrlServerResponseKey:String]()
        var pair       = [String]()
            
        for keyValue in (split(workingCopy) { $0 == "\r\n" })
        {
            pair = split(keyValue, maxSplit: 1, allowEmptySlices: false) { $0 == "=" }
                
            if let
                keyRaw = pair.first?.lowercaseString,
                key    = SqrlServerResponseKey(rawValue: keyRaw)
            where pair.count == 2
            {
                dictionary[key] = pair.last
            }
        }
        return (dictionary.isEmpty) ? nil : dictionary
    }
}