//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

public protocol ByteStream {
    mutating func nextByte() -> UInt8?
    func peekByte() -> UInt8?
    func hasMoreBytes() -> Bool
    mutating func skipBytes(count: UInt32)
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
    
    public mutating func skipBytes(count: UInt32) {
        bytes.removeFirst(Int(count))
    }
    
    public func peekByte() -> UInt8? {
        return bytes.first
    }
    
    public func hasMoreBytes() -> Bool {
        return bytes.count > 0
    }
    
    
}



extension ByteStream {
    mutating func expectByte() throws -> UInt8 {
        if let b = self.nextByte() {
            return b
        } else {
            throw ParseError.unexpectedEof
        }
    }
    
    mutating func expect4() throws -> UInt32 {
        let b1 = UInt32(try expectByte())
        let b2 = UInt32(try expectByte())
        let b3 = UInt32(try expectByte())
        let b4 = UInt32(try expectByte())
        return b1 | (b2 << 8) | (b3 << 16) | (b4 << 24)
    }
    
    mutating func expect8() throws -> UInt64 {
        let b1 = UInt64(try expect4())
        let b2 = UInt64(try expect4())
        return b1 | (b2 << 32)
    }
}
