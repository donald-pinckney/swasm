//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/27/19.
//

import Foundation
import Parser


public struct VM {
    private let store: Store
    
    private var activations: [Activation]
    private var values: [Value]
    private var code: [Instr]
    
    private var ip: Int
    
    init(initialStore: Store, initialActivations: [Activation]) {
        store = initialStore
        activations = initialActivations
        values = []
        code = []
        ip = 0
    }
    
//    private mutating func push
    
    private mutating func invokeUnchecked(funcAddr: FuncAddr, args: [Value]) throws -> [Value] {
        let f = store.funcs[funcAddr]

        let ft: FuncType
        let m: ModuleInst
        let code: Function
        
        switch f {
        case let .HostFunction(type: _, hostfunc: h):
            return h(args)
//            values.append(contentsOf: h(args))
        case let .ModuleFunction(type: _ft, module: _m, code: _code):
            ft = _ft
            m = _m
            code = _code
        }
        
        let ts = code.locals
        let val0 = ts.map { Value(zeroValueFor: $0) }
        let F = Frame(locals: args + val0, module: m)
        let A = Activation(n: ft.to.count, frame: F)
        activations.append(A)
        
        let block = Instr.block(BlockType.result(ft.to), code.body.instrs)
        
        return try evaluate(instrs: [block])
    }
    
    public mutating func invoke(funcAddr: FuncAddr, args: [Value]) throws -> [Value] {
        let funcinst = store.funcs[funcAddr]
        let ts = funcinst.type.from
        guard ts.count == args.count else {
            throw ExecutionError.argCountMismatch(expected: ts.count, received: args.count)
        }
        
        for (arg, t) in zip(args, ts) {
            guard arg.type == t else {
                throw ExecutionError.typeMismatch(expected: t, received: arg.type)
            }
        }
        
        return try invokeUnchecked(funcAddr: funcAddr, args: args)
    }
    
    private mutating func evaluate(instruction: Instr) throws {
        switch instruction {
        case .i32Const(let x):
            values.append(Value.i32(x))
        default:
            unimplemented()
        }
    }
    
    private mutating func evaluate() throws {
        while ip < code.count {
            let instr = code[ip]
            ip += 1
            
            try evaluate(instruction: instr)
        }
    }
    
    mutating func evaluate(instrs: [Instr]) throws -> [Value] {
        code = instrs
        ip = 0
        try evaluate()
        return values
    }
    
    mutating func evaluateToValue(instrs: [Instr]) throws -> Value {
        let ret = try evaluate(instrs: instrs)
        assert(ret.count == 1)
        return ret[0]
    }
}
