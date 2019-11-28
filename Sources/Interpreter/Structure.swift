//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/26/19.
//

import Foundation
import Parser

func unimplemented(function: String = #function) -> Never {
    fatalError("Not yet implemented: \(function)")
}


public typealias Addr = Int
public typealias FuncAddr = Addr
public typealias TableAddr = Addr
public typealias MemAddr = Addr
public typealias GlobalAddr = Addr

typealias HostFunc = ([Value]) -> [Value] // Currently host funcs are not supported

enum ValidationError: Error {
    case importCountNotMatched(given: Int, expected: Int)
    case externTypesDontMatch(given: ExternType, expected: ExternType)
}



enum ExecutionError: Error {
    case tableTooBig(len: UInt32, max: UInt32)
    case memoryTooBig(len: UInt32, max: UInt32)
    case validationError(err: ValidationError)
    case tableInitializationOutOfBounds
    case memInitializationOutOfBounds
    case argCountMismatch(expected: Int, received: Int)
    case typeMismatch(expected: ValueType, received: ValueType)
}

public enum Value {
    case i32(Int32)
    case i64(Int64)
    case f32(Float32)
    case f64(Float64)
    
    init(zeroValueFor: ValueType) {
        switch zeroValueFor {
        case .i32:
            self = .i32(0)
        case .i64:
            self = .i64(0)
        case .f32:
            self = .f32(0)
        case .f64:
            self = .f64(0)
        }
    }
    
    func assert_i32() -> Int32 {
        switch self {
        case .i32(let x):
            return x
        default:
            fatalError("UNEXPECTED ERROR: Expected value to be i32, got: \(self)")
        }
    }
    
    var type: ValueType {
        switch self {
        case .i32(_):
            return ValueType.i32
        case .i64(_):
            return ValueType.i64
        case .f32(_):
            return ValueType.f32
        case .f64(_):
            return ValueType.f64
        }
    }
}

public enum ExternVal {
    case Func(FuncAddr)
    case Table(TableAddr)
    case Mem(MemAddr)
    case Global(GlobalAddr)
}

final class ModuleInst {
    internal init(types: [FuncType], funcAddrs: [FuncAddr], tableAddrs: [TableAddr], memAddrs: [MemAddr], globalAddrs: [GlobalAddr], exports: [ExportInst]) {
        self.types = types
        self.funcAddrs = funcAddrs
        self.tableAddrs = tableAddrs
        self.memAddrs = memAddrs
        self.globalAddrs = globalAddrs
        self.exports = exports
    }
    internal convenience init() {
        self.init(types: [], funcAddrs: [], tableAddrs: [], memAddrs: [], globalAddrs: [], exports: [])
    }
    
    var types: [FuncType]
    var funcAddrs: [FuncAddr]
    var tableAddrs: [TableAddr]
    var memAddrs: [MemAddr]
    var globalAddrs: [GlobalAddr]
    var exports: [ExportInst]
}

enum FuncInst {
    case ModuleFunction(type: FuncType, module: ModuleInst, code: Function)
    case HostFunction(type: FuncType, hostfunc: HostFunc)
    
    var type: FuncType {
        switch self {
        case .ModuleFunction(type: let t, module: _, code: _):
            return t
        case .HostFunction(type: let t, hostfunc: _):
            return t
        }
    }
}

struct TableInst {
    var elem: [FuncAddr?]
    let max: UInt32?
    
    mutating func growTable(n: UInt32) throws {
        let len = UInt32(elem.count) + n
        if let theMax = max, theMax < len {
            throw ExecutionError.tableTooBig(len: len, max: theMax)
        }
        elem.append(contentsOf: [FuncAddr?](repeating: nil, count: Int(n)))
    }
}

struct MemInst {
    var data: [UInt8] // data.count is always a multiple of 65536
    let max: UInt32? // in units of 65536, that is data.count / 65536 <= max
    
    mutating func growMem(n: UInt32) throws {
        let len = UInt32(data.count) / 65536
        if len > 65536 {
            throw ExecutionError.memoryTooBig(len: len, max: 65536)
        }
        if let theMax = max, theMax < len {
            throw ExecutionError.memoryTooBig(len: len, max: theMax)
        }
        let newBytes = [UInt8](repeating: 0, count: Int(n * 65536))
        data.append(contentsOf: newBytes)
    }
}

struct GlobalInst {
    let value: Value
    let mut: Mut
}

struct ExportInst {
    let name: String
    let value: ExternVal
}

struct Activation {
    let n: Int
    let frame: Frame
}
struct Frame {
    let locals: [Value]
    let module: ModuleInst
}


struct Store {
    var funcs: [FuncInst]
    var tables: [TableInst]
    var mems: [MemInst]
    var globals: [GlobalInst]
    
    mutating func allocFunc(f: Function, m: ModuleInst) -> FuncAddr {
        let a = funcs.count
        let t = m.types[f.type]
        let fInst = FuncInst.ModuleFunction(type: t, module: m, code: f)
        funcs.append(fInst)
        return a
    }
    
    mutating func allocHostFunc(t: FuncType, h: @escaping HostFunc) -> FuncAddr {
        let a = funcs.count
        let fInst = FuncInst.HostFunction(type: t, hostfunc: h)
        funcs.append(fInst)
        return a
    }
    
    mutating func allocTable(t: TableType) -> TableAddr {
        let n = t.limits.getMin()
        let m = t.limits.getMax()
        
        let a = tables.count
        let tableInst = TableInst(elem: [FuncAddr?](repeating: nil, count: Int(n)), max: m)
        tables.append(tableInst)
        return a
    }
    
    mutating func allocMem(t: MemType) -> MemAddr {
        let n = t.limits.getMin()
        let m = t.limits.getMax()
        
        let a = mems.count
        let memSize = n * 65536
        let memInst = MemInst(data: [UInt8](repeating: 0, count: Int(memSize)), max: m)
        mems.append(memInst)
        return a
    }
    
    mutating func allocGlobal(t: GlobalType, val: Value) -> GlobalAddr {
        let a = globals.count
        let globalInst = GlobalInst(value: val, mut: t.mut)
        globals.append(globalInst)
        return a
    }
    
    
    func externfuncs(e: [ExternVal]) -> [FuncAddr] {
        return e.compactMap {
            switch $0 {
            case .Func(let f): return f
            default: return nil
            }
        }
    }
    func externtables(e: [ExternVal]) -> [TableAddr] {
        return e.compactMap {
            switch $0 {
            case .Table(let t): return t
            default: return nil
            }
        }
    }
    func externmems(e: [ExternVal]) -> [MemAddr] {
        return e.compactMap {
            switch $0 {
            case .Mem(let m): return m
            default: return nil
            }
        }
    }
    func externglobals(e: [ExternVal]) -> [GlobalAddr] {
        return e.compactMap {
            switch $0 {
            case .Global(let g): return g
            default: return nil
            }
        }
    }
    
    
    mutating func allocModule(module: Module, externVals: [ExternVal], vals: [Value]) -> ModuleInst {
        
        let moduleinst = ModuleInst()
        
        moduleinst.types = module.types

        let funcaddrs = externfuncs(e: externVals) + module.funcs.map { allocFunc(f: $0, m: moduleinst) }
        let tableaddrs = externtables(e: externVals) + module.tables.map { allocTable(t: $0) }
        let memaddrs = externmems(e: externVals) + module.mems.map { allocMem(t : $0) }
        let globaladdrs = externglobals(e: externVals) + module.globals.enumerated().map { allocGlobal(t: $1.type, val: vals[$0]) }

        let exportinsts = module.exports.map { export -> ExportInst in
            let externVal: ExternVal
            switch export.exportDescription {
            case .Func(let f):
                externVal = .Func(funcaddrs[Int(f.x)])
            case .Table(let t):
                externVal = .Table(tableaddrs[Int(t.x)])
            case .Mem(let m):
                externVal = .Mem(memaddrs[Int(m.x)])
            case .Global(let g):
                externVal = .Global(globaladdrs[Int(g.x)])
            }
            return ExportInst(name: export.name, value: externVal)
        }
        
        moduleinst.funcAddrs = funcaddrs
        moduleinst.tableAddrs = tableaddrs
        moduleinst.memAddrs = memaddrs
        moduleinst.globalAddrs = globaladdrs
        moduleinst.exports = exportinsts
        
        return moduleinst
    }
    
    mutating func instantiate(module: Module, externvals: [ExternVal]) throws -> VM {
        let externtypes = try validate(module: module).exports
        guard externtypes.count == externvals.count else {
            throw ExecutionError.validationError(err: .importCountNotMatched(given: externvals.count, expected: externtypes.count))
        }
        
        for (externval, externtype) in zip(externvals, externtypes) {
            let t = try validate(store: self, val: externval)
            guard isSubtype(lhs: t, rhs: externtype) else {
                throw ExecutionError.validationError(err: .externTypesDontMatch(given: t, expected: externtype))
            }
        }
        
        let moduleinst_im = ModuleInst(types: [], funcAddrs: [], tableAddrs: [], memAddrs: [], globalAddrs: externglobals(e: externvals), exports: [])
        let F_im = Frame(locals: [], module: moduleinst_im)
        let A_im = Activation(n: 0, frame: F_im)
        
        let vals = try module.globals.map { global -> Value in
            var vm_im = VM(initialStore: self, initialActivations: [A_im])
            return try vm_im.evaluateToValue(instrs: global.initExpr.instrs)
        }

        let moduleinst = allocModule(module: module, externVals: externvals, vals: vals)
        
        let F = Frame(locals: [], module: moduleinst)
        let A = Activation(n: 0, frame: F)

        let eos = try module.elems.map { elem -> Int32 in
            var vm_eo = VM(initialStore: self, initialActivations: [A])
            let eo = try vm_eo.evaluateToValue(instrs: elem.offset.instrs).assert_i32()
            let tableaddr = moduleinst.tableAddrs[Int(elem.table.x)]
            let tableinst = self.tables[tableaddr]
            let eend = eo + Int32(elem.initIdxs.count)
            if eend > tableinst.elem.count {
                throw ExecutionError.tableInitializationOutOfBounds
            }
            return eo
        }
        
        let dos = try module.data.map { data -> Int32 in
            var vm_do = VM(initialStore: self, initialActivations: [A])
            let _do = try vm_do.evaluateToValue(instrs: data.offset.instrs).assert_i32()
            let memaddr = moduleinst.memAddrs[Int(data.data.x)]
            let meminst = self.mems[memaddr]
            let dend = _do + Int32(data.initBytes.count)
            
            if dend > meminst.data.count {
                throw ExecutionError.memInitializationOutOfBounds
            }
            return _do
        }
        
        
        for (i, elem) in module.elems.enumerated() {
            let tableaddr = moduleinst.tableAddrs[Int(elem.table.x)]
            
            for (j, funcidx) in elem.initIdxs.enumerated() {
                let funcaddr = moduleinst.funcAddrs[Int(funcidx.x)]
                self.tables[tableaddr].elem[Int(eos[i]) + j] = funcaddr
            }
        }
        
        
        for (i, data) in module.data.enumerated() {
            let memaddr = moduleinst.memAddrs[Int(data.data.x)]

            for (j, b) in data.initBytes.enumerated() {
                self.mems[memaddr].data[Int(dos[i]) + j] = b
            }
        }
        
        
        var vm = VM(initialStore: self, initialActivations: [])
        if let start = module.start {
            let startFuncAddr = moduleinst.funcAddrs[Int(start.x)]
            let _ = try vm.invoke(funcAddr: startFuncAddr, args: [])
        }
        
        return vm
    }
}

enum ExternType {
    case Func(FuncType), Table(TableType), Mem(MemType), Global(GlobalType)
}

func validate(module: Module) throws -> (imports: [ExternType], exports: [ExternType]) {
    // TODO: Implement!
    return (imports: [], exports: [])
}

func validate(store: Store, val: ExternVal) throws -> ExternType {
    unimplemented()
}

func isSubtype(lhs: ExternType, rhs: ExternType) -> Bool {
    unimplemented()
}


public extension Module {
    func instantiate(externvals: [ExternVal] = []) throws -> VM {
        var store = Store(funcs: [], tables: [], mems: [], globals: [])
        return try store.instantiate(module: self, externvals: externvals)
        
    }
}
