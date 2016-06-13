import Foundation

let date1 = NSDate(timeIntervalSinceNow: 0)
let date2 = NSDate(timeIntervalSinceNow: 1000)

if date1.compare(date2) == .OrderedDescending { print("de") }
if date1.compare(date2) == .OrderedAscending { print("As") }
