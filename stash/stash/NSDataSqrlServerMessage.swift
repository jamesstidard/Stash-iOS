//
//  NSDataSqrlServerMessage.swift
//  stash
//
//  Created by James Stidard on 15/04/2015.
//  Copyright (c) 2015 James Stidard. All rights reserved.
//

import Foundation

struct TIF : RawOptionSetType, BooleanType {
    typealias RawValue = UInt
    private var value  = UInt(0)
    
    init(_ value: UInt)        { self.value = value }
    init(rawValue value: UInt) { self.value = value }
    init(nilLiteral: ())       { self.value = 0 }
    
    static var allZeros: TIF   { return self(0) }
    static func fromMask(raw: UInt) -> TIF { return self(raw) }
    
    var rawValue:  UInt { return self.value }
    var boolValue: Bool { return self.value != 0 }
    
    static var CurrentIDMatch:        TIF { return TIF(0x01) }
    static var PreviousIDMatch:       TIF { return TIF(0x02) }
    static var IPsMatched:            TIF { return TIF(0x04) }
    static var SQRLDisabled:          TIF { return TIF(0x08) }
    static var FunctionsNotSupported: TIF { return TIF(0x10) }
    static var TransientError:        TIF { return TIF(0x20) }
    static var CommandFailed:         TIF { return TIF(0x40) }
    static var ClientFailure:         TIF { return TIF(0x80) }
}

enum SqrlServerResponseKey: String
{
    case Version = "ver", Nut = "nut", TIF = "tif", Query = "qry", ServersFriendlyName = "sfn"
}

extension NSData
{
    func sqrlServerResponse() -> [SqrlServerResponseKey:String]?
    {
        if let postBase64URL = NSString(data: self, encoding: NSASCIIStringEncoding) as? String {
            return postBase64URL.sqrlServerResponse()
        }
        return nil
    }
}