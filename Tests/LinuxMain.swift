import XCTest

//import swasmTests
import parserTests

var tests = [XCTestCaseEntry]()
//tests += swasmTests.allTests()
tests += parserTests.allTests()
XCTMain(tests)
