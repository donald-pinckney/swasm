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
    public let from: [ValueType]
    public let to: [ValueType]
}

public enum Limits {
    case Min(UInt32)
    case MinMax(UInt32, UInt32)
    
    public func getMin() -> UInt32 {
        switch self {
        case .Min(let m):
            return m
        case .MinMax(let m, _):
            return m
        }
    }
    
    public func getMax() -> UInt32? {
        switch self {
        case .Min(_):
            return nil
        case .MinMax(_, let M):
            return M
        }
    }
}

public struct MemType {
    public let limits: Limits
}

public enum ElemType {
    case funcref
}

public struct TableType {
    public let limits: Limits
    let elemType: ElemType
}

public enum Mut {
    case const, `var`
}

public struct GlobalType {
    public let mut: Mut
    public let valType: ValueType
}


public typealias TypeIdx = Int

//public struct TypeIdx {
//    let x: UInt32
//}
public struct FuncIdx {
    public let x: UInt32
}
public struct TableIdx {
    public let x: UInt32
}
public struct MemIdx {
    public let x: UInt32
}
public struct GlobalIdx {
    public let x: UInt32
}
public struct LocalIdx {
    public let x: UInt32
}
public struct LabelIdx {
    public let l: UInt32
}

public struct MemArg {
    let align: UInt32
    let offset: UInt32
}

public enum Instr {
    // MARK: Control Instructions
    case unreachable, nop, `return`
    case block(BlockType, [Instr]), loop(BlockType, [Instr]), `if`(BlockType, [Instr], [Instr])
    case br(LabelIdx), brIf(LabelIdx), brTable([LabelIdx], LabelIdx)
    case call(FuncIdx)
    case callIndirect(TypeIdx)
    
    // MARK: Parametric Instructions
    case drop, select
    
    // MARK: Variable Instructions
    case localGet(LocalIdx), localSet(LocalIdx), localTee(LocalIdx)
    case globalGet(GlobalIdx), globalSet(GlobalIdx)
    
    // MARK: Memory Instructions
    case i32Load(MemArg), i64Load(MemArg), f32Load(MemArg), f64Load(MemArg), i32Load8_s(MemArg), i32Load8_u(MemArg), i32Load16_s(MemArg), i32Load16_u(MemArg), i64Load8_s(MemArg), i64Load8_u(MemArg), i64Load16_s(MemArg), i64Load16_u(MemArg), i64Load32_s(MemArg), i64Load32_u(MemArg), i32Store(MemArg), i64Store(MemArg), f32Store(MemArg), f64Store(MemArg), i32Store8(MemArg), i32Store16(MemArg), i64Store8(MemArg), i64Store16(MemArg), i64Store32(MemArg), memorySize, memoryGrow
    
    // MARK: Numeric Instructions
    case i32Const(Int32), i64Const(Int64), f32Const(Float), f64Const(Double)
    case i32Eqz, i32Eq, i32Ne, i32Lt_s, i32Lt_u, i32Gt_s, i32Gt_u, i32Le_s, i32Le_u, i32Ge_s, i32Ge_u
    case i64Eqz, i64Eq, i64Ne, i64Lt_s, i64Lt_u, i64Gt_s, i64Gt_u, i64Le_s, i64Le_u, i64Ge_s, i64Ge_u
    case f32Eq, f32Ne, f32Lt, f32Gt, f32Le, f32Ge
    case f64Eq, f64Ne, f64Lt, f64Gt, f64Le, f64Ge
    case i32Clz, i32Ctz, i32Popcnt, i32Add, i32Sub, i32Mul, i32Div_s, i32Div_u, i32Rem_s, i32Rem_u, i32And, i32Or, i32Xor, i32Shl, i32Shr_s, i32Shr_u, i32Rotl, i32Rotr
    case i64Clz, i64Ctz, i64Popcnt, i64Add, i64Sub, i64Mul, i64Div_s, i64Div_u, i64Rem_s, i64Rem_u, i64And, i64Or, i64Xor, i64Shl, i64Shr_s, i64Shr_u, i64Rotl, i64Rotr
    case f32Abs, f32Neg, f32Ceil, f32Floor, f32Trunc, f32Nearest, f32Sqrt, f32Add, f32Sub, f32Mul, f32Div, f32Min, f32Max, f32Copysign
    case f64Abs, f64Neg, f64Ceil, f64Floor, f64Trunc, f64Nearest, f64Sqrt, f64Add, f64Sub, f64Mul, f64Div, f64Min, f64Max, f64Copysign
    case i32Wrap_i64, i32Trunc_f32_s, i32Trunc_f32_u, i32Trunc_f64_s, i32Trunc_f64_u
    case i64Extend_i32_s, i64Extend_i32_u, i64Trunc_f32_s, i64Trunc_f32_u, i64Trunc_f64_s, i64Trunc_f64_u
    case f32Convert_i32_s, f32Convert_i32_u, f32Convert_i64_s, f32Convert_i64_u, f32Demote_f64
    case f64Convert_i32_s, f64Convert_i32_u, f64Convert_i64_s, f64Convert_i64_u, f64Promote_f32
    case i32Reinterpret_f32, i64Reinterpret_f64, f32Reinterpret_i32, f64Reinterpret_i64
}

public struct Expr {
    public let instrs: [Instr]
}

enum ImportDescription {
    case Func(TypeIdx), Table(TableType), Mem(MemType), Global(GlobalType)
}
public struct Import {
    let moduleName: String
    let name: String
    let importDescription: ImportDescription
}

public enum ExportDescription {
    case Func(FuncIdx), Table(TableIdx), Mem(MemIdx), Global(GlobalIdx)
}
public struct Export {
    public let name: String
    public let exportDescription: ExportDescription
}


public struct Function {
    public let type: TypeIdx
    let locals: [ValueType]
    let body: Expr
}


public struct Module: CustomStringConvertible {
    public let types: [FuncType]
    public let funcs: [Function]
    public let tables: [TableType]
    public let mems: [MemType]
    public let globals: [(type: GlobalType, initExpr: Expr)]
    public let elems: [(table: TableIdx, offset: Expr, initIdxs: [FuncIdx])]
    public let data: [(data: MemIdx, offset: Expr, initBytes: [UInt8])]
    public let start: FuncIdx?
    public let imports: [Import]
    public let exports: [Export]
    
    public var description: String {
        "Types:\n\(types)\n\nFuncs:\n\(funcs)\n\nTables:\n\(tables)\n\nMems:\n\(mems)\n\nGlobals:\n\(globals)\n\nElems:\n\(elems)\n\nData:\n\(data)\n\nStart:\n\(String(describing: start))\n\nImports:\n\(imports)\n\nExports:\n\(exports)"
    }    
}
