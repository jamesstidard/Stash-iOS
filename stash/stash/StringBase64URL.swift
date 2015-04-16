//
//  StringBase64URL.swift
//  stash
//
//  Created by James Stidard on 15/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

extension String
{
    func base64URLEncodedString(#padding: Bool) -> String?
    {
        return self.dataUsingEncoding(NSUTF8StringEncoding)?.base64URLString(padding: padding)
    }
    
    init?(fromBase64URLData data: NSData)
    {
        self = MF_Base64Codec.base64StringFromData(data).stringByReplacingOccurrencesOfString("+", withString: "-")
            .stringByReplacingOccurrencesOfString("/", withString: "_")
    }
    
    init(fromBase64URLString string: String)
    {
        string.stringByReplacingOccurrencesOfString("+", withString: "-")
              .stringByReplacingOccurrencesOfString("/", withString: "_")
        self = NSString(fromBase64String: string) as String
    }
}