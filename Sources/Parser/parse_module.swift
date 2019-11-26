//
//  File.swift
//
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

extension WasmParser {
    // MARK: Modules
    
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
}
