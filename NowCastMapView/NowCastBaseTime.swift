//
//  NowCastBaseTime.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

public class NowCastBaseTime: NSObject, NSCoding, Comparable {
	private let kForecastPeriod = 12
	private var baseTimeArr = [String]()

	public override var description: String {
		return baseTimeString(atIndex: 0) ?? "error"
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init()
		if let baseTimeArr = aDecoder.decodeObjectForKey("baseTimeArr") as? [String] {
			self.baseTimeArr = baseTimeArr
		}
		else { return nil }
	}

	public func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(baseTimeArr, forKey: "baseTimeArr")
	}

	public required init?(baseTimeData data: NSData) {
		super.init()
		baseTimeArr = [String]()

		let parser = NSXMLParser(data: data)
		let parserDelegate =  NowCastBaseTimeParser()
		parser.delegate = parserDelegate;

		if parser.parse() {
			let inputFormatter = NSDateFormatter()
			inputFormatter.dateFormat = "yyyyMMddHHmm"
			inputFormatter.timeZone = NSTimeZone(abbreviation: "UTC")

			let outputFormatter = NSDateFormatter()
			outputFormatter.dateFormat = "yyyyMMddHHmm"
			outputFormatter.timeZone = NSTimeZone(abbreviation: "UTC")

			if let firstBaseTime = parserDelegate.parsedArr.first {
				if let forecastTime = inputFormatter.dateFromString(firstBaseTime) {
					for var i = kForecastPeriod ; i >= 1 ; i -= 1 {
//					for i in kForecastPeriod...1 {
						let baseTimeDate = NSDate(timeInterval: NSTimeInterval(i*60*5), sinceDate: forecastTime)
						self.baseTimeArr.append(outputFormatter.stringFromDate(baseTimeDate))
//						i -= 1
					}
					baseTimeArr += parserDelegate.parsedArr
				}
			}
			return
		}

		return nil
	}

	public func count() -> Int {
		return self.baseTimeArr.count
	}

	public func range() -> Range<Int> {
		// -35...0...12
		return (-self.baseTimeArr.count+kForecastPeriod+1...kForecastPeriod)
	}

	public func baseTimeString(atIndex index: Int) -> String? {
		// convert from 12...-35 to 0...47
		if self.range() ~= index { return baseTimeArr[-index+kForecastPeriod] }

		return nil
	}

	public func baseTimeDate(atIndex index: Int) -> NSDate? {
		var retVal: NSDate? = nil
		if self.range() ~= index {
			if let baseTime = baseTimeString(atIndex: index) {
				let inputFormatter = NSDateFormatter()
				inputFormatter.dateFormat = "yyyyMMddHHmm"
				inputFormatter.timeZone = NSTimeZone(abbreviation: "UTC")

				retVal =  inputFormatter.dateFromString(baseTime)
			}
		}

		return retVal
	}

	public func compare(other: NowCastBaseTime) -> NSComparisonResult {
		// this api should return not optional value. and index: 0 must success.
		return self.baseTimeDate(atIndex: 0)!.compare(other.baseTimeDate(atIndex: 0)!)
	}
}