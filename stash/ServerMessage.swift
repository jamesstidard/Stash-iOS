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
    let URL:         Foundation.URL
    let dictionary:  [SqrlServerResponseKey : String]
    let string:      String
    let data:        Data
    let responseURL: Foundation.URL?
    
    init(URL: Foundation.URL, dictionary: [SqrlServerResponseKey : String], string: String, data: Data, responseURL: Foundation.URL?)
    {
        self.URL         = URL
        self.data        = data
        self.dictionary  = dictionary
        self.string      = string
        self.responseURL = responseURL
    }
    
    init?(data: Data?, response: URLResponse?)
    {
        var responseURL: Foundation.URL?
        
        if let
            data       = data,
            let string     = NSString(data: data, encoding: String.Encoding.ascii.rawValue) as? String,
            let dictionary = string.sqrlServerValueDictionary(),
            let URL        = response?.url
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
