//
//  BaseTime.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

/**
A `BaseTime` structure contains a set of indexes represents forecast timeline as of specific forecast time.
A `BaseTime` instances are parsed and instantiated from a simple xml data
fetched from "http://www.jma.go.jp/jp/highresorad/highresorad_tile/tile_basetime.xml".
*/
public struct BaseTime {

	// MARK: - Public Properties

	public let range: CountableClosedRange<Int> // -35...0..12
	public var count: Int { return range.count }

	// MARK: - Private Properties

	private let ftStrings: [String]
	private let ftDates: [Date]

	// MARK: - Functions

	public init?(baseTimeData data: Data) {
		// parse xml
		let parser = XMLParser(data: data)
		let parserDelegate =  BaseTimeParser()
		parser.delegate = parserDelegate
		if !parser.parse() { return nil }

		// inputFormatter
		let inputFormatter = DateFormatter()
		inputFormatter.dateFormat = "yyyyMMddHHmm"
		inputFormatter.timeZone = TimeZone(abbreviation: "UTC")

		// create ftDates from baseTime
		// contains only past date
		var ftDates = [Date]()
		for index in 0 ..< parserDelegate.parsedArr.count {
			guard let date = inputFormatter.date(from: parserDelegate.parsedArr[index]) else { return nil }
			ftDates.append(date)
		}

		// create ftDates with fts for forecast
		let base = ftDates[0]
		BaseTimeModel.Constants.fts.enumerated().forEach { _, minutes in
			if minutes == 0 { return }
			ftDates.insert(base.addingTimeInterval(TimeInterval(minutes*60)), at: 0)
		}

		// outputFormatter
		let outputFormatter = DateFormatter()
		outputFormatter.dateFormat = "yyyyMMddHHmm"
		outputFormatter.timeZone = TimeZone(abbreviation: "UTC")

		// create ftStrings from ftDates
		var ftStrings = [String]()
		ftDates.forEach { date in
			ftStrings.append(outputFormatter.string(from: date))
		}

		self.ftDates = ftDates
		self.ftStrings = ftStrings
		range = BaseTime.index(from: ftDates.endIndex-1) ... BaseTime.index(from: ftDates.startIndex)

		return
	}

	public subscript(index: Int) -> String {
		return ftStrings[BaseTime.arrayIndex(from: index)]
	}

	public subscript(index: Int) -> Date {
		return ftDates[BaseTime.arrayIndex(from: index)]
	}
}

// MARK: - Static Functions

extension BaseTime {
	/// convert from 0...47 to -35...12
	static fileprivate func index(from arrayIndex: Int) -> Int {
		return -(arrayIndex - (BaseTimeModel.Constants.fts.count - 1))
	}

	/// convert from -35...12 to 0...47
	static fileprivate func arrayIndex(from index: Int) -> Int {
		return (-index) + (BaseTimeModel.Constants.fts.count - 1)
	}
}

// MARK: - CustomStringConvertible

extension BaseTime: CustomStringConvertible {
	public var description: String {
		return self[0]
	}
}

// MARK: - CustomDebugStringConvertible

extension BaseTime: CustomDebugStringConvertible {
	public var debugDescription: String {
//		var output: [String] = []
//
//		output.append("[url]: \(url)")
//		output.append(image != nil ? "[image]: not nil" : "[image]: nil")
//
//		return output.joined(separator: "\n")
		return description
	}
}
