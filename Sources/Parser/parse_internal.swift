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


class InternalParser {
    var stream: ByteStream
    
    init(stream: ByteStream) {
        self.stream = stream
    }
    
    // MARK: Helpers
    
    @discardableResult func nextByte(mustBeOneOf: Set<UInt8>, errorMessage: String = #function) throws -> UInt8 {
        let b = try byte()
        if !mustBeOneOf.contains(b) {
            throw ParseError.expectedByte(received: b, wanted: mustBeOneOf, message: errorMessage)
        } else {
            return b
        }
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
    
    func s_variable_len() throws -> Int64 {
        let size = 64
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
    
    func u32() throws -> UInt32 {
        UInt32(try u_variable_len())
    }
    func u64() throws -> UInt64 {
        UInt64(try u_variable_len())
    }
    
    func s32() throws -> Int32 {
        Int32(try s_variable_len())
    }
    func s64() throws -> Int64 {
        Int64(try s_variable_len())
    }
    
    func i32() throws -> Int32 {
        try s32()
    }
    func i64() throws -> Int64 {
        try s64()
    }
    
    func f32() throws -> Float {
        Float(bitPattern: try stream.expect4())
    }
    
    func f64() throws -> Double {
        Double(bitPattern: try stream.expect8())
    }
    
    func vec<T>(nonterminal: () throws -> T) throws -> [T] {
        let n = try u32()
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
        try ValueType(try byte())
    }
    
    func blocktype() throws -> BlockType {
        try BlockType(try byte())
    }
    
    func functype() throws -> FuncType {
        try nextByte(mustBeOneOf: [0x60])
        let fromTypes = try vec(nonterminal: valtype)
        let toTypes = try vec(nonterminal: valtype)
        return FuncType(from: fromTypes, to: toTypes)
    }
    
    func limits() throws -> Limits {
        let b = try nextByte(mustBeOneOf: [0x00, 0x01])
        
        let min = try u32()
        
        switch b {
        case 0x00:
            return .Min(min)
        case 0x01:
            return .MinMax(min, try u32())
        default:
            impossible()
        }
    }
    
    func memtype() throws -> MemType {
        MemType(limits: try limits())
    }
    
    func elemtype() throws -> ElemType {
        try nextByte(mustBeOneOf: [0x70])
        return .funcref
    }
    
    func tabletype() throws -> TableType {
        let et = try elemtype()
        let lim = try limits()
        return TableType(limits: lim, elemType: et)
    }
    
    func mut() throws -> Mut {
        let b = try nextByte(mustBeOneOf: [0x00, 0x01])
        switch b {
        case 0x00:
            return .const
        case 0x01:
            return .var
        default:
            impossible()
        }
    }
    
    func globaltype() throws -> GlobalType {
        let t = try valtype()
        let m = try mut()
        return GlobalType(mut: m, valType: t)
    }
    
    // MARK: Instructions
    
    
    
    func module() throws -> Module {
        unimplemented()
    }
    
    
}

