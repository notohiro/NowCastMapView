//
//  NowCastBaseTimeTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/20/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest
import AwesomeCache

class NowCastBaseTimeTests: AmeBaseTestCase {
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
}
