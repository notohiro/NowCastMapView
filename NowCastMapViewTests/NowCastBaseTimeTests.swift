//
//  NowCastBaseTimeTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/20/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest
import AwesomeCache

class NowCastBaseTimeTests: NowCastBaseTestCase {
	func testInitWithXML() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			// test .count()
			XCTAssertEqual(baseTime.count(), 48)
			// test .range()
			XCTAssertEqual(baseTime.range(), (-35...12))
		}
		else { XCTFail() }
	}

	func testInitWithCache() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			let kLastSavedBaseTimeKey = "lastSavedBaseTime"
			// to release sharedCache object for exec init?(coder aDecoder: NSCoder)
			autoreleasepool {
				// save
				let sharedCache = try! Cache<NowCastBaseTime>(name: NowCastBaseTimeCacheName)
				sharedCache.removeAllObjects()
				sharedCache.setObject(baseTime, forKey: kLastSavedBaseTimeKey)
			}

			waitForSeconds(SecondsForTimeout)

			autoreleasepool {
				// restore
				let sharedCache = try! Cache<NowCastBaseTime>(name: NowCastBaseTimeCacheName)
				if let restoredBaseTime = sharedCache.objectForKey(kLastSavedBaseTimeKey) {
					// test .count()
					XCTAssertEqual(restoredBaseTime.count(), 48)
					// test .range()
					XCTAssertEqual(restoredBaseTime.range(), (-35...12))
				}
				else { XCTFail() }
			}
		}
		else { XCTFail() }
	}

	func testInitWithInvalidData() {
		XCTAssertNil(NowCastBaseTime(baseTimeData: NSData()))
	}

	func testBaseTimeStringAtIndex() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			for i in baseTime.range() {
				// test .baseTimeStringAtIndex(index index: Int)
				let baseTimeStringAtIndex = baseTime.baseTimeString(atIndex: i)
				XCTAssertNotNil(baseTimeStringAtIndex)
			}

			XCTAssertNil(baseTime.baseTimeString(atIndex: baseTime.range().startIndex-1))
		}
		else { XCTFail() }
	}

	func testBaseTimeDateAtIndex() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			for i in baseTime.range() {
				// test .baseTimeDateAtIndex(index index: Int)
				let baseTimeDateAtIndex = baseTime.baseTimeDate(atIndex: i)
				XCTAssertNotNil(baseTimeDateAtIndex)
			}

			XCTAssertNil(baseTime.baseTimeDate(atIndex: baseTime.range().startIndex-1))
		}
		else { XCTFail() }
	}

	func testCompare() {
		if let oldBaseTime = getBaseTimeFrom("OldBaseTime"), newBaseTime = getBaseTimeFrom("NewBaseTime") {
			XCTAssertEqual(oldBaseTime.compare(oldBaseTime), (NSComparisonResult).OrderedSame)
			XCTAssertEqual(oldBaseTime.compare(newBaseTime), (NSComparisonResult).OrderedAscending)
			XCTAssertEqual(newBaseTime.compare(oldBaseTime), (NSComparisonResult).OrderedDescending)
		}
		else { XCTFail() }
	}

	func testEquatable() {
		guard let oldBaseTime = getBaseTimeFrom("OldBaseTime"), newBaseTime = getBaseTimeFrom("NewBaseTime") else { XCTFail(); return }
		let optionalOldBaseTime: NowCastBaseTime? = oldBaseTime
		let optionalOldBaseTime2 = getBaseTimeFrom("OldBaseTime")
		let optionalNewBaseTime = getBaseTimeFrom("NewBaseTime")
		let optionalBaseTime: NowCastBaseTime? = nil

		// compare between Not Optionals
		// same objects
		XCTAssertTrue(oldBaseTime == oldBaseTime)
		XCTAssertFalse(oldBaseTime != oldBaseTime)
		// different objects
		XCTAssertFalse(oldBaseTime == newBaseTime)
		XCTAssertTrue(oldBaseTime != newBaseTime)

		// compare between Not Optional and Optional
		// same objects
		XCTAssertTrue(oldBaseTime == optionalOldBaseTime)
		XCTAssertTrue(optionalOldBaseTime == oldBaseTime)
		XCTAssertFalse(oldBaseTime != optionalOldBaseTime)
		XCTAssertFalse(optionalOldBaseTime != oldBaseTime)
		// same baseTime
		XCTAssertTrue(oldBaseTime == optionalOldBaseTime2)
		XCTAssertTrue(optionalOldBaseTime2 == oldBaseTime)
		XCTAssertFalse(oldBaseTime != optionalOldBaseTime2)
		XCTAssertFalse(optionalOldBaseTime2 != oldBaseTime)
		// different baseTime
		XCTAssertFalse(oldBaseTime == optionalNewBaseTime)
		XCTAssertFalse(optionalNewBaseTime == oldBaseTime)
		XCTAssertTrue(oldBaseTime != optionalNewBaseTime)
		XCTAssertTrue(optionalNewBaseTime != oldBaseTime)
		// Optional(nil)
		XCTAssertFalse(oldBaseTime == optionalBaseTime)
		XCTAssertFalse(optionalBaseTime == oldBaseTime)
		XCTAssertTrue(oldBaseTime != optionalBaseTime)
		XCTAssertTrue(optionalBaseTime != oldBaseTime)
		// nil
		XCTAssertFalse(oldBaseTime == nil)
		XCTAssertFalse(nil == oldBaseTime)
		XCTAssertTrue(oldBaseTime != nil)
		XCTAssertTrue(nil != oldBaseTime)

		// compare between Optionals
		// same objects
		XCTAssertTrue(optionalOldBaseTime == optionalOldBaseTime)
		XCTAssertFalse(optionalOldBaseTime != optionalOldBaseTime)
		// same baseTime
		XCTAssertTrue(optionalOldBaseTime == optionalOldBaseTime2)
		XCTAssertTrue(optionalOldBaseTime2 == optionalOldBaseTime)
		XCTAssertFalse(optionalOldBaseTime != optionalOldBaseTime2)
		XCTAssertFalse(optionalOldBaseTime2 != optionalOldBaseTime)
		// different baseTime
		XCTAssertFalse(optionalOldBaseTime == optionalNewBaseTime)
		XCTAssertFalse(optionalNewBaseTime == optionalOldBaseTime)
		XCTAssertTrue(optionalOldBaseTime != optionalNewBaseTime)
		XCTAssertTrue(optionalNewBaseTime != optionalOldBaseTime)
		// Optional(nil)
		XCTAssertTrue(optionalBaseTime == optionalBaseTime)
		XCTAssertFalse(optionalBaseTime != optionalBaseTime)
		// nil
		XCTAssertFalse(optionalOldBaseTime == nil)
		XCTAssertFalse(nil == optionalOldBaseTime)
		XCTAssertTrue(optionalOldBaseTime != nil)
		XCTAssertTrue(nil != optionalOldBaseTime)
		// Optional(nil) and nil
		XCTAssertTrue(optionalBaseTime == nil)
		XCTAssertTrue(nil == optionalBaseTime)
		XCTAssertFalse(optionalBaseTime != nil)
		XCTAssertFalse(nil != optionalBaseTime)
	}
}
