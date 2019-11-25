import XCTest

import swasmTests

var tests = [XCTestCaseEntry]()
tests += swasmTests.allTests()
tests += parserTests.allTests()
XCTMain(tests)
