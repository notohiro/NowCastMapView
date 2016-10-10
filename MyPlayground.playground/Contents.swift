import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

class myClass {
	struct myStruct {
		var index = 0
	}

	var val = myStruct(index: 0)

	func add(_ value: Int) {
		OperationQueue.main.addOperation {
			self.val.index += value
			print("\(self.val.index)")
//			self.byThread(value)
		}
	}

	func byThread(_ value: Int) {
		val.index += value
		print("\(val.index)")
	}
}

let val = myClass()

val.add(1)
val.add(2)
print("\(val.val.index)")

