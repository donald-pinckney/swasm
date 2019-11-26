//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

extension WasmParser {
    // MARK: Values
    
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
            shift += 6
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
    
    
    
    func name() throws -> String {
        let utf8 = try vec(nonterminal: byte)()
        if let s = String(bytes: utf8, encoding: .utf8) {
            return s
        } else {
            throw ParseError.utf8DecodingFailed(bytes: utf8)
        }
    }
}
