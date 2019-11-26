//
//  File.swift
//
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

extension WasmParser {
    // MARK: Indices
    
    func typeidx() throws -> TypeIdx {
        TypeIdx(x: try u32())
    }
    func funcidx() throws -> FuncIdx {
        FuncIdx(x: try u32())
    }
    func tableidx() throws -> TableIdx {
        TableIdx(x: try u32())
    }
    func memidx() throws -> MemIdx {
        MemIdx(x: try u32())
    }
    func globalidx() throws -> GlobalIdx {
        GlobalIdx(x: try u32())
    }
    func localidx() throws -> LocalIdx {
        LocalIdx(x: try u32())
    }
    func labelidx() throws -> LabelIdx {
        LabelIdx(l: try u32())
    }
    
    // MARK: Sections
    
    enum Section {
        case Custom(String, [UInt8])
        case Type([FuncType])
        case Import([Import])
        case Function([TypeIdx])
        case Table([TableType])
        case Memory([MemType])
        case Global([(type: GlobalType, init: Expr)])
        case Export([Export])
        case Start(FuncIdx)
        case Element([(table: TableIdx, offset: Expr, init: [FuncIdx])])
        case Code([([ValueType], Expr)])
        case Data([(data: MemIdx, offset: Expr, init: [UInt8])])
    }
    
    func customSection(size: UInt32) throws -> Section {
        stream.skipBytes(count: size)
        return .Custom("Custom sections not implemented", [])
    }
    
    func typeSection(size: UInt32) throws -> Section {
        .Type(try vec(nonterminal: functype)())
    }
    
    func `import`() throws -> Import {
        let mod = try name()
        let nm = try name()
        let desc: ImportDescription
        switch try byte() {
        case 0x00:
            desc = .Func(try typeidx())
        case 0x01:
            desc = .Table(try tabletype())
        case 0x02:
            desc = .Mem(try memtype())
        case 0x03:
            desc = .Global(try globaltype())
        case let b:
            throw ParseError.invalidImportDescriptor(d: b)
        }
        
        return Import(moduleName: mod, name: nm, importDescription: desc)
    }
    
    func importSection(size: UInt32) throws -> Section {
        .Import(try vec(nonterminal: `import`)())
    }
    
    func functionSection(size: UInt32) throws -> Section {
        .Function(try vec(nonterminal: typeidx)())
    }
        
    func tableSection(size: UInt32) throws -> Section {
        .Table(try vec(nonterminal: tabletype)())
    }
    
    func memorySection(size: UInt32) throws -> Section {
        .Memory(try vec(nonterminal: memtype)())
    }
    
    func global() throws -> (type: GlobalType, init: Expr) {
        let gt = try globaltype()
        let e = try expr()
        return (type: gt, init: e)
    }
    
    func globalSection(size: UInt32) throws -> Section {
        .Global(try vec(nonterminal: global)())
    }
    
    func export() throws -> Export {
        let nm = try name()
        let desc: ExportDescription
        switch try byte() {
        case 0x00:
            desc = .Func(try funcidx())
        case 0x01:
            desc = .Table(try tableidx())
        case 0x02:
            desc = .Mem(try memidx())
        case 0x03:
            desc = .Global(try globalidx())
        case let b:
            throw ParseError.invalidExportDescriptor(d: b)
        }
        
        return Export(name: nm, exportDescription: desc)
    }
    
    func exportSection(size: UInt32) throws -> Section {
        .Export(try vec(nonterminal: export)())
    }
    
    func startSection(size: UInt32) throws -> Section {
        .Start(try funcidx())
    }
    
    func element() throws -> (table: TableIdx, offset: Expr, init: [FuncIdx]) {
        let x = try tableidx()
        let e = try expr()
        let ys = try vec(nonterminal: funcidx)()
        return (table: x, offset: e, init: ys)
    }
    
    func elementSection(size: UInt32) throws -> Section {
        .Element(try vec(nonterminal: element)())
    }
    
    func locals() throws -> [ValueType] {
        let n = try u32()
        let t = try valtype()
        return [ValueType](repeating: t, count: Int(n))
    }
    
    func code() throws -> ([ValueType], Expr) {
        let _ = try u32() // Code size, ignored currently
        
        let types = try vec(nonterminal: locals)()
        let e = try expr()
        
        return (Array(types.joined()), e)
    }
    
    func codeSection(size: UInt32) throws -> Section {
        .Code(try vec(nonterminal: code)())
    }
    
    func data() throws -> (data: MemIdx, offset: Expr, init: [UInt8]) {
        let x = try memidx()
        let e = try expr()
        let bs = try vec(nonterminal: byte)()
        return (data: x, offset: e, init: bs)
    }
    
    func dataSection(size: UInt32) throws -> Section {
        .Data(try vec(nonterminal: data)())
    }
    
    // MARK: Section Dispatch
    
    func section() throws -> Section? {
        let sectionIdTable = [customSection, typeSection, importSection, functionSection, tableSection, memorySection, globalSection, exportSection, startSection, elementSection, codeSection, dataSection]

        guard let id = stream.nextByte() else {
            return nil
        }
        
        // Size of section, not used
        let size = try u32()
            
        guard id <= 11 else {
            throw ParseError.invalidSectionId(id: id)
        }
        
        return try sectionIdTable[Int(id)](size)
    }
    
    // MARK: Modules
    
    func module() throws -> Module {
        try nextByte(mustBe: 0x00, errorMessage: "magic")
        try nextByte(mustBe: 0x61, errorMessage: "magic")
        try nextByte(mustBe: 0x73, errorMessage: "magic")
        try nextByte(mustBe: 0x6D, errorMessage: "magic")
        
        try nextByte(mustBe: 0x01, errorMessage: "version")
        try nextByte(mustBe: 0x00, errorMessage: "version")
        try nextByte(mustBe: 0x00, errorMessage: "version")
        try nextByte(mustBe: 0x00, errorMessage: "version")
        
        var typesec: [FuncType] = []
        var importsec: [Import] = []
        var funcsec: [TypeIdx] = []
        var tablesec: [TableType] = []
        var memsec: [MemType] = []
        var globalsec: [(type: GlobalType, init: Expr)] = []
        var exportsec: [Export] = []
        var startsec: FuncIdx? = nil
        var elemsec: [(table: TableIdx, offset: Expr, init: [FuncIdx])] = []
        var codesec: [([ValueType], Expr)] = []
        var datasec: [(data: MemIdx, offset: Expr, init: [UInt8])] = []
        
        while let sec = try section() {
            switch sec {
            case let .Custom(name, _):
                print("Unhandled custom section: \(name)")
            case let .Type(x):
                typesec = x
            case let .Import(x):
                importsec = x
            case let .Function(x):
                funcsec = x
            case let .Table(x):
                tablesec = x
            case let .Memory(x):
                memsec = x
            case let .Global(x):
                globalsec = x
            case let .Export(x):
                exportsec = x
            case let .Start(x):
                startsec = x
            case let .Element(x):
                elemsec = x
            case let .Code(x):
                codesec = x
            case let .Data(x):
                datasec = x
            }
        }
        
        guard codesec.count == funcsec.count else {
            throw ParseError.mismatchedCodeAndFuncSectionLengths(codeLen: codesec.count, funcLen: funcsec.count)
        }
        
        let funcs = zip(funcsec, codesec).map { Function(type: $0.0, locals: $0.1.0, body: $0.1.1) }
        
        return Module(
                types: typesec,
                funcs: funcs,
                tables: tablesec,
                mems: memsec,
                globals: globalsec,
                elems: elemsec,
                data: datasec,
                start: startsec,
                imports: importsec,
                exports: exportsec
        )
    }
}
