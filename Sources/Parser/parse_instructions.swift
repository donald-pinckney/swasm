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
    func labelidx() throws -> LabelIndex {
        unimplemented()
    }
    func funcidx() throws -> FuncIdx {
        unimplemented()
    }
    func typeidx() throws -> TypeIdx {
        unimplemented()
    }
    func localidx() throws -> LocalIdx {
        unimplemented()
    }
    func globalidx() throws -> GlobalIdx {
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
            try! self.nextByte(mustBeOneOf: [0x0B], errorMessage: "instr: block")
            return .block(rt, instrs)
        }
        opcodeTable[0x03] = {
            let rt = try self.blocktype()
            var instrs: [Instr] = []
            while self.stream.peekByte() != 0x0B {
                instrs.append(try self.instr())
            }
            try! self.nextByte(mustBeOneOf: [0x0B], errorMessage: "instr: loop")
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
                try! self.nextByte(mustBeOneOf: [0x0B], errorMessage: "instr: loop")
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
            try self.nextByte(mustBeOneOf: [0x00], errorMessage: "instr: call_indirect (opcode 0x11)")
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
    }
    
    func instr() throws -> Instr {
        unimplemented()
    }
}
