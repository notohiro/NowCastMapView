//
//  BaseTime.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

public struct BaseTimeContext {
	public var baseTime: BaseTime
	public var index: Int

	public init(baseTime: BaseTime, index: Int) {
		self.baseTime = baseTime
		self.index = index
	}
}

public class BaseTime: NSObject, NSCoding, Comparable {
	private let forecastPeriod = 12
	private var baseTimeArr = [String]()

	public override var description: String {
		return baseTimeString(atIndex: 0) ?? "error"
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init()
		if let baseTimeArr = aDecoder.decodeObjectForKey("baseTimeArr") as? [String] {
			self.baseTimeArr = baseTimeArr
		} else {
			return nil
		}
	}

	public func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(baseTimeArr, forKey: "baseTimeArr")
	}

	public required init?(baseTimeData data: NSData) {
		super.init()
		baseTimeArr = [String]()

		let parser = NSXMLParser(data: data)
		let parserDelegate =  BaseTimeParser()
		parser.delegate = parserDelegate

		if !parser.parse() { return nil }

		let inputFormatter = NSDateFormatter()
		inputFormatter.dateFormat = "yyyyMMddHHmm"
		inputFormatter.timeZone = NSTimeZone(abbreviation: "UTC")

		let outputFormatter = NSDateFormatter()
		outputFormatter.dateFormat = "yyyyMMddHHmm"
		outputFormatter.timeZone = NSTimeZone(abbreviation: "UTC")

		guard let firstBaseTime = parserDelegate.parsedArr.first else { return nil }
		guard let forecastTime = inputFormatter.dateFromString(firstBaseTime) else { return nil }

		var forecastDateArr = [NSDate]()
		for i in 1...forecastPeriod {
			forecastDateArr.append(NSDate(timeInterval: NSTimeInterval(i*60*5), sinceDate: forecastTime))
		}

		// reverse array
		forecastDateArr.sortInPlace {
			if $0.compare($1) == .OrderedAscending {
				return false
			} else {
				return true
			}
		}

		baseTimeArr += forecastDateArr.map { outputFormatter.stringFromDate($0) }
		baseTimeArr += parserDelegate.parsedArr

		// temporary fix until AME-141
		if baseTimeArr.count != 48 { return nil }

		return
	}

	public func count() -> Int {
		return baseTimeArr.count
	}

	public func range() -> Range<Int> {
		// -35...0...12
		return (-baseTimeArr.count+forecastPeriod+1...forecastPeriod)
	}

	public func baseTimeString(atIndex index: Int) -> String? {
		// convert from 12...-35 to 0...47
		if range() ~= index { return baseTimeArr[-index+forecastPeriod] }

		return nil
	}

	public func baseTimeDate(atIndex index: Int) -> NSDate? {
		if range() ~= index {
			guard let baseTime = baseTimeString(atIndex: index) else { return nil }

			let inputFormatter = NSDateFormatter()
			inputFormatter.dateFormat = "yyyyMMddHHmm"
			inputFormatter.timeZone = NSTimeZone(abbreviation: "UTC")

			return inputFormatter.dateFromString(baseTime)
		}

		return nil
	}

	public func compare(other: BaseTime) -> NSComparisonResult {
		// this api should return not optional value. and index: 0 must success.
		return baseTimeDate(atIndex: 0)!.compare(other.baseTimeDate(atIndex: 0)!)
	}
}
