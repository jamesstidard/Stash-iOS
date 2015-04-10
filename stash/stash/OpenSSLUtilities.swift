//
//  OpenSSLUtilities.swift
//  stash
//
//  Created by James Stidard on 10/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

class OpenSSLUtilities {
    
    class func initialiseCryptoLibrary() {
        OPENSSL_add_all_algorithms_noconf()
    }
}