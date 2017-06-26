//
//  Logger.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/05/07.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import Foundation

class Logger {
	enum LogLevel: String {
		case debug = "[debug]"
		case warning = "[wargning]"
		case error = "[error]"
	}

	static func log(logLevel: LogLevel,
	                message: String? = nil,
	                classFile: String = #file,
	                functionName: String = #function,
	                lineNumber: Int = #line) {
		// Separator
		NSLog("-------------------------")

		// Date
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"

		// print date, class, function
		var output = "[\(dateFormatter.string(from: Date()))] "
		output += "[NowCastMapView] "
		output += "\(logLevel.rawValue) "
		output += "\(classFile.lastPathComponent):\(lineNumber) - \(functionName)"
		NSLog(output)

		// print message
		if let message = message {
			NSLog(message)
		}
	}
}

extension String {
	public var lastPathComponent: String {
		return (self as NSString).lastPathComponent
	}
}
