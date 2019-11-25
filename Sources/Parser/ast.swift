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

public struct LabelIndex {
    
}

public struct FuncIdx {
    
}

public struct TypeIdx {
    
}

public struct LocalIdx {
    
}

public struct GlobalIdx {
    
}

public struct MemArg {
    
}

public enum Instr {
    // MARK: Control Instructions
    case unreachable, nop, `return`
    case block(BlockType, [Instr]), loop(BlockType, [Instr]), `if`(BlockType, [Instr], [Instr])
    case br(LabelIndex), brIf(LabelIndex), brTable([LabelIndex], LabelIndex)
    case call(FuncIdx)
    case callIndirect(TypeIdx)
    
    // MARK: Parametric Instructions
    case drop, select
    
    // MARK: Variable Instructions
    case localGet(LocalIdx), localSet(LocalIdx), localTee(LocalIdx)
    case globalGet(GlobalIdx), globalSet(GlobalIdx)
    
    // MARK: Memory Instructions
    case i32Load(MemArg), i64Load(MemArg), f32Load(MemArg), f64Load(MemArg), i32Load8_s(MemArg), i32Load8_u(MemArg), i32Load16_s(MemArg), i32Load16_u(MemArg), i64Load8_s(MemArg), i64Load8_u(MemArg), i64Load16_s(MemArg), i64Load16_u(MemArg), i64Load32_s(MemArg), i64Load32_u(MemArg), i32Store(MemArg), i64Store(MemArg), f32Store(MemArg), f64Store(MemArg), i32Store8(MemArg), i32Store16(MemArg), i64Store8(MemArg), i64Store16(MemArg), i64Store32(MemArg), memorySize, memoryGrow
}

public struct Module {
    let x: Int
}
