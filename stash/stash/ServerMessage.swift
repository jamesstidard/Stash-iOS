//
//  ServerResponse.swift
//  stash
//
//  Created by James Stidard on 18/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

struct ServerMessage
{
    let URL:         NSURL
    let dictionary:  [SqrlServerResponseKey : String]
    let string:      String
    let data:        NSData
    let responseURL: NSURL?
    
    init(URL: NSURL, dictionary: [SqrlServerResponseKey : String], string: String, data: NSData, responseURL: NSURL?)
    {
        self.URL         = URL
        self.data        = data
        self.dictionary  = dictionary
        self.string      = string
        self.responseURL = responseURL
    }
    
    init?(data: NSData?, response: NSURLResponse?)
    {
        var responseURL: NSURL?
        
        if let
            data       = data,
            string     = NSString(data: data, encoding: NSASCIIStringEncoding) as? String,
            dictionary = string.sqrlServerValueDictionary(),
            URL        = response?.URL
        {
            if let newQueryPath = dictionary[.Query] {
                responseURL = URL.urlByReplacingQueryPath(newQueryPath)
            }
            
            self.init(URL: URL, dictionary: dictionary, string: string, data: data, responseURL: responseURL)
        }
        else {
            return nil
        }
    }
}