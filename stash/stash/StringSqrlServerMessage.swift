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
    func sqrlServerResponse() -> [SqrlServerResponseKey:String]?
    {
        let postString = String(fromBase64URLString: self)
        var dictionary = [SqrlServerResponseKey:String]()
        var pair       = [String]()
            
        for keyValue in (split(postString) { $0 == "\r\n" })
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