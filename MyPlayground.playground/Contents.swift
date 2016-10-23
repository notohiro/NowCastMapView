import Foundation
//import PlaygroundSupport

//PlaygroundPage.current.needsIndefiniteExecution = true


var arr = ["a", "b"]
arr.enumerated().forEach { index, val in
	print(index)
}

arr.insert("c", at: 0)
