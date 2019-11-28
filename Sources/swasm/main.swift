import Parser
import Foundation
import Interpreter

let path = CommandLine.arguments.count == 2 ? CommandLine.arguments[1] : "/Users/donaldpinckney/UMass/research/WasmContinuations/swasm/Wasm/fibonacci.wasm"

let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
var data = [UInt8](repeating: 0, count: fileData.count)
fileData.copyBytes(to: &data, count: fileData.count)

let module = try parseModule(stream: InMemoryBytes(bytes: data)).get()
print(module)

let vm = try module.instantiate()
print(vm)
