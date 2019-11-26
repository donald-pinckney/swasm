//
//  File.swift
//  
//
//  Created by Donald Pinckney on 11/25/19.
//

import Foundation

public enum ParseError: Error {
    case unexpectedEof
    case expectedByte(received: UInt8, wanted: Set<UInt8>, message: String?)
    case utf8DecodingFailed(bytes: [UInt8])
    case invalidValueType(byte: UInt8)
    case invalidOpcode(opcodeByte: UInt8)
    case invalidSectionId(id: UInt8)
    case invalidImportDescriptor(d: UInt8)
    case invalidExportDescriptor(d: UInt8)
    case mismatchedCodeAndFuncSectionLengths(codeLen: Int, funcLen: Int)
}

public func parseModule(stream: ByteStream) throws -> Result<Module, ParseError> {
    unimplemented()
}

