//
//  IdentitySqrl.swift
//  stash
//
//  Created by James Stidard on 13/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

enum SQRLCommand {
    case Query, Ident, Enable, Disable
}


extension Identity
{
    func sqrlTask(password: String, command: SQRLCommand, sqrlLink: NSURL) -> NSURLSessionTask?
    {
        switch command
        {
//        case .Query: return self.sqrlQueryTask(password: password, sqrlLink: sqrlLink)
            
        default: return nil
        }
    }
    
//    func sqrlQueryTask(#password: String, sqrlLink: NSURL) -> NSURLSessionTask
//    {
//        
//    }
}