//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

public enum ValueType {
    case i32, i64, f32, f64
    
    init(_ b: UInt8) throws {
        switch b {
        case 0x7F:
            self = .i32
        case 0x7E:
            self = .i64
        case 0x7D:
            self = .f32
        case 0x7C:
            self = .f64
        case let b:
            throw ParseError.invalidValueType(byte: b)
        }
    }
}

public enum BlockType {
    case empty
    case result(ValueType)
    
    init(_ b: UInt8) throws {
        switch b {
        case 0x40:
            self = .empty
        default:
            self = .result(try ValueType(b))
        }
    }
}

public struct FuncType {
    let from: [ValueType]
    let to: [ValueType]
}

public enum Limits {
    case Min(UInt32)
    case MinMax(UInt32, UInt32)
}

public struct MemType {
    let limits: Limits
}

public enum ElemType {
    case funcref
}

public struct TableType {
    let limits: Limits
    let elemType: ElemType
}

public enum Mut {
    case const, `var`
}

public struct GlobalType {
    let mut: Mut
    let valType: ValueType
}

public struct Module {
    let x: Int
}

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

public enum ParseError: Error {
    case unexpectedEof
    case expectedByte(received: UInt8, wanted: Set<UInt8>, message: String?)
    case utf8DecodingFailed(bytes: [UInt8])
    case invalidValueType(byte: UInt8)
}

public func parseModule(stream: ByteStream) throws -> Module {
    return Module(x: 8)
}

