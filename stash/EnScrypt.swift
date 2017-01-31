//
//  EnScrypt.swift
//  stash
//
//  Created by James Stidard on 26/01/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

let EnScryptDefaultNCost: UInt64           = 512
let EnScryptDefaultRCost: UInt32           = 256
let EnScryptDefaultParallelisation: UInt32 = 1
let EnScryptDefaultIterations              = 50

struct EnScryptParameters {
    fileprivate static let DefaultNCost           = UInt64(512)
    fileprivate static let DefaultRCost           = UInt32(256)
    fileprivate static let DefaultParallelisation = UInt32(1)
    fileprivate static let DefaultIterations      = Int(50)
    
    var N = DefaultNCost
    var r = DefaultRCost
    var p = DefaultParallelisation
    var i = DefaultIterations
    
    init(type: EnScryptStorageType)
    {
        switch type
        {
        case .local:  self.i = 5
        case .export: self.i = 50
        }
    }
}

enum EnScryptStorageType {
    case local, export
}

class EnScrypt {
    
    class func salsa208Sha256(_ password: Data?, salt: Data?, N: UInt64, r: UInt32, p: UInt32, i: Int) -> Data?
    {
        var salt = salt
        var finalOut: NSMutableData?
        
        for x in 1...i
        {
            if let out = Scrypt.salsa208Sha256(password, salt: salt, N: N, r: r, p: p)
            {
                // set new salt as output of last Scrypt
                salt = out.mutableCopy() as? Data
                // if first cycle then store initial out into final and get pointer
                if x == 1 { finalOut = out.mutableCopy() as? NSMutableData }
                // else, XOR the out with the running finalOut and store back into out
                else { finalOut = finalOut! ^ out }
            }
            else { return nil }
        }
        
        return finalOut as Data?
    }
    
    class func salsa208Sha256(_ password: Data?, salt: Data?, storageType: EnScryptStorageType) -> Data?
    {
        let salt = salt
        let sParams = EnScryptParameters(type: storageType)
        return self.salsa208Sha256(password, salt: salt, N: sParams.N, r: sParams.r, p: sParams.p, i: sParams.i)
    }
}
