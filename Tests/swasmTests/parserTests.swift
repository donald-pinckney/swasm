import XCTest
import class Foundation.Bundle
@testable import Parser

final class parserTests: XCTestCase {
    
    private func makeParser(_ bytes: [UInt8]) -> InternalParser {
        return InternalParser(stream: InMemoryBytes(bytes: bytes))
    }
    private func doParse<T>(_ bytes: [UInt8], nonterminal: (InternalParser) -> () throws -> T) -> T {
        let p = makeParser(bytes)
        return try! nonterminal(p)()
    }
    
    func testUnsignedInts() throws {
        XCTAssertEqual(doParse([0xe5, 0x8e, 0x26], nonterminal: InternalParser.u_variable_len), 624485)
        XCTAssertEqual(doParse([0x03], nonterminal: InternalParser.u_variable_len), 3)
        XCTAssertEqual(doParse([0x83, 0x00], nonterminal: InternalParser.u_variable_len), 3)        
    }
    
    func testSignedInts() throws {
        let s_var_len = { (p: InternalParser) -> () throws -> Int64 in
            return { () -> Int64 in
                return try p.s_variable_len(size: 64)
            }
        }
        
        XCTAssertEqual(doParse([0xc0, 0xbb, 0x78], nonterminal: s_var_len), -123456)
        XCTAssertEqual(doParse([0x7e], nonterminal: s_var_len), -2)
        XCTAssertEqual(doParse([0xfe, 0x7f], nonterminal: s_var_len), -2)
        XCTAssertEqual(doParse([0xfe, 0xff, 0x7f], nonterminal: s_var_len), -2)
    }
    
    func test_f32() throws {
        XCTAssertEqual(doParse([0x33, 0x33, 0x63, 0x42], nonterminal: InternalParser.f32), 56.8)
    }

    // 33 33 63 42

    static var allTests = [
        ("testUnsignedInts", testUnsignedInts),
    ]
}
