//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

typealias InstrProduction = () throws -> Instr

func opcode0(_ instr: Instr) -> InstrProduction {
    return {
        instr
    }
}

func opcode1<T>(_ instr: @escaping (T) -> Instr, nonterminal: @escaping () throws -> T) -> InstrProduction {
    return {
        instr(try nonterminal())
    }
}

func opcode2<T, U>(_ instr: @escaping (T, U) -> Instr, nonterminal1: @escaping () throws -> T, nonterminal2: @escaping () throws -> U) -> InstrProduction {
    return {
        let t = try nonterminal1()
        let u = try nonterminal2()
        return instr(t, u)
    }
}


extension WasmParser {
    // MARK: Instructions
    
    
    func memarg() throws -> MemArg {
        unimplemented()
    }
    
    

    func buildOpcodeTable() {
        
        // MARK: Control Instructions
        
        opcodeTable[0x00] = opcode0(.unreachable)
        opcodeTable[0x01] = opcode0(.nop)
        opcodeTable[0x02] = {
            let rt = try self.blocktype()
            var instrs: [Instr] = []
            while self.stream.peekByte() != 0x0B {
                instrs.append(try self.instr())
            }
            try! self.nextByte(mustBe: 0x0B, errorMessage: "instr: block")
            return .block(rt, instrs)
        }
        opcodeTable[0x03] = {
            let rt = try self.blocktype()
            var instrs: [Instr] = []
            while self.stream.peekByte() != 0x0B {
                instrs.append(try self.instr())
            }
            try! self.nextByte(mustBe: 0x0B, errorMessage: "instr: loop")
            return .loop(rt, instrs)
        }
        opcodeTable[0x04] = {
            let rt = try self.blocktype()
            var instrs: [Instr] = []
            while true {
                let peek = self.stream.peekByte()
                if peek == 0x05 || peek == 0x0B {
                    break
                }
                instrs.append(try self.instr())
            }
            
            let b = try! self.nextByte(mustBeOneOf: [0x05, 0x0B], errorMessage: "instr: if")
            switch b {
            case 0x0B:
                return .if(rt, instrs, [])
            case 0x05:
                var elseInstrs: [Instr] = []
                while self.stream.peekByte() != 0x0B {
                    elseInstrs.append(try self.instr())
                }
                try! self.nextByte(mustBe: 0x0B, errorMessage: "instr: loop")
                return .if(rt, instrs, elseInstrs)
            default:
                impossible()
            }
        }
        opcodeTable[0x0C] = opcode1(Instr.br, nonterminal: labelidx)
        opcodeTable[0x0D] = opcode1(Instr.brIf, nonterminal: labelidx)
        opcodeTable[0x0E] = opcode2(Instr.brTable, nonterminal1: vec(nonterminal: labelidx), nonterminal2: labelidx)
        opcodeTable[0x0F] = opcode0(.return)
        opcodeTable[0x10] = opcode1(Instr.call, nonterminal: funcidx)
        opcodeTable[0x11] = {
            let x = try self.typeidx()
            try self.nextByte(mustBe: 0x00, errorMessage: "instr: call_indirect (opcode 0x11)")
            return .callIndirect(x)
        }
        
        // MARK: Parametric Instructions
        
        opcodeTable[0x1A] = opcode0(.drop)
        opcodeTable[0x1B] = opcode0(.select)
        
        // MARK: Variable Instructions
        
        opcodeTable[0x20] = opcode1(Instr.localGet, nonterminal: localidx)
        opcodeTable[0x21] = opcode1(Instr.localSet, nonterminal: localidx)
        opcodeTable[0x22] = opcode1(Instr.localTee, nonterminal: localidx)
        opcodeTable[0x23] = opcode1(Instr.globalGet, nonterminal: globalidx)
        opcodeTable[0x24] = opcode1(Instr.globalSet, nonterminal: globalidx)
        
        
        // MARK: Memory Instructions

        let opcode_memarg = { instr in
            opcode1(instr, nonterminal: self.memarg)
        }
        
        opcodeTable[0x28] = opcode_memarg(Instr.i32Load)
        opcodeTable[0x29] = opcode_memarg(Instr.i64Load)
        opcodeTable[0x2A] = opcode_memarg(Instr.f32Load)
        opcodeTable[0x2B] = opcode_memarg(Instr.f64Load)
        opcodeTable[0x2C] = opcode_memarg(Instr.i32Load8_s)
        opcodeTable[0x2D] = opcode_memarg(Instr.i32Load8_u)
        opcodeTable[0x2E] = opcode_memarg(Instr.i32Load16_s)
        opcodeTable[0x2F] = opcode_memarg(Instr.i32Load16_u)
        opcodeTable[0x30] = opcode_memarg(Instr.i64Load8_s)
        opcodeTable[0x31] = opcode_memarg(Instr.i64Load8_u)
        opcodeTable[0x32] = opcode_memarg(Instr.i64Load16_s)
        opcodeTable[0x33] = opcode_memarg(Instr.i64Load16_u)
        opcodeTable[0x34] = opcode_memarg(Instr.i64Load32_s)
        opcodeTable[0x35] = opcode_memarg(Instr.i64Load32_u)
        opcodeTable[0x36] = opcode_memarg(Instr.i32Store)
        opcodeTable[0x37] = opcode_memarg(Instr.i64Store)
        opcodeTable[0x38] = opcode_memarg(Instr.f32Store)
        opcodeTable[0x39] = opcode_memarg(Instr.f64Store)
        opcodeTable[0x3A] = opcode_memarg(Instr.i32Store8)
        opcodeTable[0x3B] = opcode_memarg(Instr.i32Store16)
        opcodeTable[0x3C] = opcode_memarg(Instr.i64Store8)
        opcodeTable[0x3D] = opcode_memarg(Instr.i64Store16)
        opcodeTable[0x3E] = opcode_memarg(Instr.i64Store32)
        opcodeTable[0x3F] = {
            try self.nextByte(mustBe: 0x00)
            return .memorySize
        }
        opcodeTable[0x40] = {
            try self.nextByte(mustBe: 0x00)
            return .memoryGrow
        }

        // MARK: Numeric Instructions
        
        opcodeTable[0x41] = opcode1(Instr.i32Const, nonterminal: i32)
        opcodeTable[0x42] = opcode1(Instr.i64Const, nonterminal: i64)
        opcodeTable[0x43] = opcode1(Instr.f32Const, nonterminal: f32)
        opcodeTable[0x44] = opcode1(Instr.f64Const, nonterminal: f64)
        
        opcodeTable[0x45] = opcode0(.i32Eqz)
        opcodeTable[0x46] = opcode0(.i32Eq)
        opcodeTable[0x47] = opcode0(.i32Ne)
        opcodeTable[0x48] = opcode0(.i32Lt_s)
        opcodeTable[0x49] = opcode0(.i32Lt_u)
        opcodeTable[0x4A] = opcode0(.i32Gt_s)
        opcodeTable[0x4B] = opcode0(.i32Gt_u)
        opcodeTable[0x4C] = opcode0(.i32Le_s)
        opcodeTable[0x4D] = opcode0(.i32Le_u)
        opcodeTable[0x4E] = opcode0(.i32Ge_s)
        opcodeTable[0x4F] = opcode0(.i32Ge_u)
        
        opcodeTable[0x50] = opcode0(.i64Eqz)
        opcodeTable[0x51] = opcode0(.i64Eq)
        opcodeTable[0x52] = opcode0(.i64Ne)
        opcodeTable[0x53] = opcode0(.i64Lt_s)
        opcodeTable[0x54] = opcode0(.i64Lt_u)
        opcodeTable[0x55] = opcode0(.i64Gt_s)
        opcodeTable[0x56] = opcode0(.i64Gt_u)
        opcodeTable[0x57] = opcode0(.i64Le_s)
        opcodeTable[0x58] = opcode0(.i64Le_u)
        opcodeTable[0x59] = opcode0(.i64Ge_s)
        opcodeTable[0x5A] = opcode0(.i64Ge_u)

        opcodeTable[0x5B] = opcode0(.f32Eq)
        opcodeTable[0x5C] = opcode0(.f32Ne)
        opcodeTable[0x5D] = opcode0(.f32Lt)
        opcodeTable[0x5E] = opcode0(.f32Gt)
        opcodeTable[0x5F] = opcode0(.f32Le)
        opcodeTable[0x60] = opcode0(.f32Ge)
        
        opcodeTable[0x61] = opcode0(.f64Eq)
        opcodeTable[0x62] = opcode0(.f64Ne)
        opcodeTable[0x63] = opcode0(.f64Lt)
        opcodeTable[0x64] = opcode0(.f64Gt)
        opcodeTable[0x65] = opcode0(.f64Le)
        opcodeTable[0x66] = opcode0(.f64Ge)
        
        opcodeTable[0x67] = opcode0(.i32Clz)
        opcodeTable[0x68] = opcode0(.i32Ctz)
        opcodeTable[0x69] = opcode0(.i32Popcnt)
        opcodeTable[0x6A] = opcode0(.i32Add)
        opcodeTable[0x6B] = opcode0(.i32Sub)
        opcodeTable[0x6C] = opcode0(.i32Mul)
        opcodeTable[0x6D] = opcode0(.i32Div_s)
        opcodeTable[0x6E] = opcode0(.i32Div_u)
        opcodeTable[0x6F] = opcode0(.i32Rem_s)
        opcodeTable[0x70] = opcode0(.i32Rem_u)
        opcodeTable[0x71] = opcode0(.i32And)
        opcodeTable[0x72] = opcode0(.i32Or)
        opcodeTable[0x73] = opcode0(.i32Xor)
        opcodeTable[0x74] = opcode0(.i32Shl)
        opcodeTable[0x75] = opcode0(.i32Shr_s)
        opcodeTable[0x76] = opcode0(.i32Shr_u)
        opcodeTable[0x77] = opcode0(.i32Rotl)
        opcodeTable[0x78] = opcode0(.i32Rotr)
        
        opcodeTable[0x79] = opcode0(.i64Clz)
        opcodeTable[0x7A] = opcode0(.i64Ctz)
        opcodeTable[0x7B] = opcode0(.i64Popcnt)
        opcodeTable[0x7C] = opcode0(.i64Add)
        opcodeTable[0x7D] = opcode0(.i64Sub)
        opcodeTable[0x7E] = opcode0(.i64Mul)
        opcodeTable[0x7F] = opcode0(.i64Div_s)
        opcodeTable[0x80] = opcode0(.i64Div_u)
        opcodeTable[0x81] = opcode0(.i64Rem_s)
        opcodeTable[0x82] = opcode0(.i64Rem_u)
        opcodeTable[0x83] = opcode0(.i64And)
        opcodeTable[0x84] = opcode0(.i64Or)
        opcodeTable[0x85] = opcode0(.i64Xor)
        opcodeTable[0x86] = opcode0(.i64Shl)
        opcodeTable[0x87] = opcode0(.i64Shr_s)
        opcodeTable[0x88] = opcode0(.i64Shr_u)
        opcodeTable[0x89] = opcode0(.i64Rotl)
        opcodeTable[0x8A] = opcode0(.i64Rotr)
        
        opcodeTable[0x8B] = opcode0(.f32Abs)
        opcodeTable[0x8C] = opcode0(.f32Neg)
        opcodeTable[0x8D] = opcode0(.f32Ceil)
        opcodeTable[0x8E] = opcode0(.f32Floor)
        opcodeTable[0x8F] = opcode0(.f32Trunc)
        opcodeTable[0x90] = opcode0(.f32Nearest)
        opcodeTable[0x91] = opcode0(.f32Sqrt)
        opcodeTable[0x92] = opcode0(.f32Add)
        opcodeTable[0x93] = opcode0(.f32Sub)
        opcodeTable[0x94] = opcode0(.f32Mul)
        opcodeTable[0x95] = opcode0(.f32Div)
        opcodeTable[0x96] = opcode0(.f32Min)
        opcodeTable[0x97] = opcode0(.f32Max)
        opcodeTable[0x98] = opcode0(.f32Copysign)

        opcodeTable[0x99] = opcode0(.f64Abs)
        opcodeTable[0x9A] = opcode0(.f64Neg)
        opcodeTable[0x9B] = opcode0(.f64Ceil)
        opcodeTable[0x9C] = opcode0(.f64Floor)
        opcodeTable[0x9D] = opcode0(.f64Trunc)
        opcodeTable[0x9E] = opcode0(.f64Nearest)
        opcodeTable[0x9F] = opcode0(.f64Sqrt)
        opcodeTable[0xA0] = opcode0(.f64Add)
        opcodeTable[0xA1] = opcode0(.f64Sub)
        opcodeTable[0xA2] = opcode0(.f64Mul)
        opcodeTable[0xA3] = opcode0(.f64Div)
        opcodeTable[0xA4] = opcode0(.f64Min)
        opcodeTable[0xA5] = opcode0(.f64Max)
        opcodeTable[0xA6] = opcode0(.f64Copysign)

        opcodeTable[0xA7] = opcode0(.i32Wrap_i64)
        opcodeTable[0xA8] = opcode0(.i32Trunc_f32_s)
        opcodeTable[0xA9] = opcode0(.i32Trunc_f32_u)
        opcodeTable[0xAA] = opcode0(.i32Trunc_f64_s)
        opcodeTable[0xAB] = opcode0(.i32Trunc_f64_u)
        
        opcodeTable[0xAC] = opcode0(.i64Extend_i32_s)
        opcodeTable[0xAD] = opcode0(.i64Extend_i32_u)
        
        opcodeTable[0xAE] = opcode0(.i64Trunc_f32_s)
        opcodeTable[0xAF] = opcode0(.i64Trunc_f32_u)
        opcodeTable[0xB0] = opcode0(.i64Trunc_f64_s)
        opcodeTable[0xB1] = opcode0(.i64Trunc_f64_u)
        
        opcodeTable[0xB2] = opcode0(.f32Convert_i32_s)
        opcodeTable[0xB3] = opcode0(.f32Convert_i32_u)
        opcodeTable[0xB4] = opcode0(.f32Convert_i64_s)
        opcodeTable[0xB5] = opcode0(.f32Convert_i64_u)
        opcodeTable[0xB6] = opcode0(.f32Demote_f64)
        
        opcodeTable[0xB7] = opcode0(.f64Convert_i32_s)
        opcodeTable[0xB8] = opcode0(.f64Convert_i32_u)
        opcodeTable[0xB9] = opcode0(.f64Convert_i64_s)
        opcodeTable[0xBA] = opcode0(.f64Convert_i64_u)
        opcodeTable[0xBB] = opcode0(.f64Promote_f32)
        
        opcodeTable[0xBC] = opcode0(.i32Reinterpret_f32)
        opcodeTable[0xBD] = opcode0(.i64Reinterpret_f64)
        opcodeTable[0xBE] = opcode0(.f32Reinterpret_i32)
        opcodeTable[0xBF] = opcode0(.f64Reinterpret_i64)
        
    }
    
    func instr() throws -> Instr {
        let opcodeByte = try byte()
        
        guard let production = opcodeTable[Int(opcodeByte)] else {
            throw ParseError.invalidOpcode(opcodeByte: opcodeByte)
        }
        
        return try production()
    }
    
    func expr() throws -> Expr {
        var instrs: [Instr] = []
        while self.stream.peekByte() != 0x0B {
            instrs.append(try self.instr())
        }
        try! self.nextByte(mustBe: 0x0B, errorMessage: "expr")
        
        return Expr(instrs: instrs)
    }
}
