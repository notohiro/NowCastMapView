import Foundation
//import PlaygroundSupport

//PlaygroundPage.current.needsIndefiniteExecution = true


enum Result {
	case succeeded(request: String, result: Int)
	case failed(request: String)
}

let result1 = Result.succeeded(request: "request 1", result: 1)
let result2 = Result.failed(request: "2")

switch result1 {
case let .succeeded(request, result):
	print(request)
	print(result)
default:
	break;
}

var set = Set<String>()
set.insert("a")

if set.remove("a") != nil {
	print("a")
}

if set.remove("c") != nil {
	print("c")
} else {
	print("!c")
}
