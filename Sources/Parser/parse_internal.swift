//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation


extension ByteStream {
    mutating func expectByte() throws -> UInt8 {
        if let b = self.nextByte() {
            return b
        } else {
            throw ParseError.expectedByte
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


internal class InternalParser {
    var stream: ByteStream
    
    init(stream: ByteStream) {
        self.stream = stream
    }
    
    // MARK: Values
    
    func byte() throws -> UInt8 {
        try stream.expectByte()
    }
    
    func u_variable_len() throws -> UInt64 {
        var result: UInt64 = 0;
        var shift = 0;
        while true {
            let b = try byte()
            result |= UInt64(0x7F & b) << shift
            if 0x80 & b == 0 {
                break
            }
            shift += 7
        }
        return result
    }
    
    func s_variable_len(size: Int) throws -> Int64 {
        var result: Int64 = 0;
        var shift = 0;
        
        var b: UInt8
        repeat {
            b = try byte()
            result |= Int64(0x7F & b) << shift
            shift += 7
        } while 0x80 & b != 0
        
        if shift < size && (0x40 & b != 0) {
            result |= (~0 << shift)
        }
        
        return result
    }
    
    func i_variable_len(size: Int) throws -> Int64 {
        try s_variable_len(size: size)
    }
    
    func f32() throws -> Float {
        Float(bitPattern: try stream.expect4())
    }
    
    func f64() throws -> Double {
        Double(bitPattern: try stream.expect8())
    }
    
    func vec<T>(nonterminal: () throws -> T) throws -> [T] {
        let n = try u_variable_len()
        var xs: [T] = []
        for _ in 0..<n {
            xs.append(try nonterminal())
        }
        return xs
    }
    
    func name() throws -> String {
        let utf8 = try vec(nonterminal: byte)
        if let s = String(bytes: utf8, encoding: .utf8) {
            return s
        } else {
            throw ParseError.utf8DecodingFailed(bytes: utf8)
        }
    }
    
    // MARK: Types
    
    func valtype() throws -> ValueType {
        switch try byte() {
        case 0x7F:
            return .i32
        case 0x7E:
            return .i64
        case 0x7D:
            return .f32
        case 0x7C:
            return .f64
        case let b:
            throw ParseError.invalidValueType(byte: b)
        }
    }
    
    
    func module() throws -> Module {
//        parseVector(nonterminal: parseByte)
        fatalError("unimplemented")
    }
}

