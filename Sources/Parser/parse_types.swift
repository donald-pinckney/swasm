//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

extension WasmParser {
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
}
