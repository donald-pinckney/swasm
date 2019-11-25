//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

public protocol ByteStream {
    mutating func nextByte() -> UInt8?
//    func hasMoreBytes() -> Bool
}

public struct InMemoryBytes: ByteStream {
    var bytes : [UInt8]
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    public mutating func nextByte() -> UInt8? {
        if bytes.count > 0 {
            return bytes.removeFirst()
        } else {
            return nil
        }
    }
    
//    public func hasMoreBytes() -> Bool {
//        return bytes.count > 0
//    }
}

