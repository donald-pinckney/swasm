//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation


final class WasmParser {
    var stream: ByteStream
    var opcodeTable: [InstrProduction?] = [InstrProduction?](repeating: nil, count: 0xFF + 1)
    
    init(stream: ByteStream) {
        self.stream = stream
        buildOpcodeTable()
    }
        
    @discardableResult func nextByte(mustBeOneOf: Set<UInt8>, errorMessage: String = #function) throws -> UInt8 {
        let b = try byte()
        if !mustBeOneOf.contains(b) {
            throw ParseError.expectedByte(received: b, wanted: mustBeOneOf, message: errorMessage)
        } else {
            return b
        }
    }
    
    func byte() throws -> UInt8 {
        try stream.expectByte()
    }
    
    func vec<T>(nonterminal: @escaping () throws -> T) -> (() throws -> [T]) {
        return {
            let n = try self.u32()
            var xs: [T] = []
            for _ in 0..<n {
                xs.append(try nonterminal())
            }
            return xs
        }
    }

    // Values are parsed in parse_values.swift
    // Types are parsed in parse_types.swift
    // Instructions are parsed in parse_instructions.swift
    
    func module() throws -> Module {
        unimplemented()
    }
    
    
}
