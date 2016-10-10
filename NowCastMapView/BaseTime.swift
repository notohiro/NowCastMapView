//
//  BaseTime.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

public struct BaseTime {
	private let forecastPeriod = 12
	private let baseTimeArr: [String]

	public var description: String { return baseTimeString(atIndex: 0) ?? "error" }
	public var count: Int { return baseTimeArr.count }
	public var range: CountableClosedRange<Int> { return (-baseTimeArr.count+forecastPeriod+1...forecastPeriod) } // -35...0..<13

	public init?(baseTimeData data: Data) {
		var baseTimeArr = [String]()

		let parser = XMLParser(data: data)
		let parserDelegate =  BaseTimeParser()
		parser.delegate = parserDelegate

		if !parser.parse() { return nil }

		let inputFormatter = DateFormatter()
		inputFormatter.dateFormat = "yyyyMMddHHmm"
		inputFormatter.timeZone = TimeZone(abbreviation: "UTC")

		let outputFormatter = DateFormatter()
		outputFormatter.dateFormat = "yyyyMMddHHmm"
		outputFormatter.timeZone = TimeZone(abbreviation: "UTC")

		guard let firstBaseTime = parserDelegate.parsedArr.first else { return nil }
		guard let forecastTime = inputFormatter.date(from: firstBaseTime) else { return nil }

		var forecastDateArr = [Date]()
		for i in 1...forecastPeriod {
			forecastDateArr.append(Date(timeInterval: TimeInterval(i*60*5), since: forecastTime))
		}

		// reverse array
		forecastDateArr.sort {
			if $0.compare($1) == .orderedAscending {
				return false
			} else {
				return true
			}
		}

		baseTimeArr += forecastDateArr.map { outputFormatter.string(from: $0) }
		baseTimeArr += parserDelegate.parsedArr

		// temporary fix until AME-141
		if baseTimeArr.count != 48 { return nil }

		self.baseTimeArr = baseTimeArr

		return
	}

	public func baseTimeString(atIndex index: Int) -> String? {
		// convert from 12...-35 to 0...47
		if range ~= index { return baseTimeArr[-index+forecastPeriod] }

		return nil
	}

	public func baseTimeDate(atIndex index: Int) -> Date? {
		if range ~= index {
			guard let baseTime = baseTimeString(atIndex: index) else { return nil }

			let inputFormatter = DateFormatter()
			inputFormatter.dateFormat = "yyyyMMddHHmm"
			inputFormatter.timeZone = TimeZone(abbreviation: "UTC")

			return inputFormatter.date(from: baseTime)
		}

		return nil
	}

	public func compare(_ other: BaseTime) -> ComparisonResult {
		// this api should return not optional value. and index: 0 must success.
		return baseTimeDate(atIndex: 0)!.compare(other.baseTimeDate(atIndex: 0)!)
	}
}
