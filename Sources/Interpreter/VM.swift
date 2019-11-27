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
    private let frames: [Frame]
    private let values: [Value]
    private let code: [Instr]
    private var ip: Int
    
    init(initialStore: Store, initialFrames: [Frame]) {
        store = initialStore
        frames = initialFrames
        values = []
        code = []
        ip = 0
    }
    
    private func invokeUnchecked(funcAddr: FuncAddr, args: [Value]) throws -> [Value] {
        unimplemented()
    }
    
    public func invoke(funcAddr: FuncAddr, args: [Value]) throws -> [Value] {
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
    
    func evaluate(instrs: [Instr]) throws -> [Value] {
        unimplemented()
    }
    
    func evaluateToValue(instrs: [Instr]) throws -> Value {
        let ret = try evaluate(instrs: instrs)
        assert(ret.count == 1)
        return ret[0]
    }
}
