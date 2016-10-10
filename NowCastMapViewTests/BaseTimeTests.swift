//
//  BaseTimeTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/20/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest

@testable import NowCastMapView

class BaseTimeTests: BaseTestCase {
	func testInitWithXML() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }

		// test .count()
		XCTAssertEqual(baseTime.count, 48)
		// test .range()
		XCTAssertEqual(baseTime.range, (-35...12))
	}

	func testInitWithInvalidData() {
		XCTAssertNil(BaseTime(baseTimeData: Data()))
	}

	func testBaseTimeStringAtIndex() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }

		for i in baseTime.range {
			// test .baseTimeStringAtIndex(index index: Int)
			let baseTimeStringAtIndex = baseTime.baseTimeString(atIndex: i)
			XCTAssertNotNil(baseTimeStringAtIndex)
		}

		XCTAssertNil(baseTime.baseTimeString(atIndex: baseTime.range.lowerBound-1))
	}

	func testBaseTimeDateAtIndex() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }

		for i in baseTime.range {
			// test .baseTimeDateAtIndex(index index: Int)
			let baseTimeDateAtIndex = baseTime.baseTimeDate(atIndex: i)
			XCTAssertNotNil(baseTimeDateAtIndex)
		}

		XCTAssertNil(baseTime.baseTimeDate(atIndex: baseTime.range.lowerBound-1))	}

	func testCompare() {
		guard let oldBaseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let newBaseTime = baseTime(file: "NewBaseTime") else { XCTFail(); return }

		XCTAssertEqual(oldBaseTime.compare(oldBaseTime), (ComparisonResult).orderedSame)
		XCTAssertEqual(oldBaseTime.compare(newBaseTime), (ComparisonResult).orderedAscending)
		XCTAssertEqual(newBaseTime.compare(oldBaseTime), (ComparisonResult).orderedDescending)
	}

	func testEquatable() {
		guard let oldBaseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let newBaseTime = baseTime(file: "NewBaseTime") else { XCTFail(); return }

		// same objects
		XCTAssertTrue(oldBaseTime == oldBaseTime)
		XCTAssertFalse(oldBaseTime != oldBaseTime)
		// different objects
		XCTAssertFalse(oldBaseTime == newBaseTime)
		XCTAssertTrue(oldBaseTime != newBaseTime)
	}

	func testComparable() {
		guard let oldBaseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let newBaseTime = baseTime(file: "NewBaseTime") else { XCTFail(); return }

		XCTAssertTrue(oldBaseTime < newBaseTime)
		XCTAssertFalse(oldBaseTime > newBaseTime)
	}
}
