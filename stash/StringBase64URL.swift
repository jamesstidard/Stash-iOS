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
        return self.dataUsingEncoding(String.Encoding.utf8)?.base64URLString(padding: padding)
    }
    
    init?(fromBase64URLData data: Data)
    {
        self = MF_Base64Codec.base64String(from: data).replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    init(fromBase64URLString string: String)
    {
        string.replacingOccurrences(of: "+", with: "-")
              .replacingOccurrences(of: "/", with: "_")
        if let string = NSString(fromBase64String: string) as? String {
            self = string
            return
        }
        self = ""
    }
}
