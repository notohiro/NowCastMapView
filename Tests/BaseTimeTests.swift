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

    func testSubscriptAsString() {
	    guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }

	    for index in baseTime.range {
    	    let _: String = baseTime[index]
	    }
    }

    func testSubscriptAsDate() {
	    guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }

	    for index in baseTime.range {
    	    let _: Date = baseTime[index]
	    }
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

    func testCompare() {
	    guard let oldBaseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
	    guard let newBaseTime = baseTime(file: "NewBaseTime") else { XCTFail(); return }

	    XCTAssertTrue(oldBaseTime < newBaseTime)
	    XCTAssertFalse(newBaseTime < oldBaseTime)

	    XCTAssertTrue(oldBaseTime <= newBaseTime)
	    XCTAssertFalse(newBaseTime <= oldBaseTime)

	    XCTAssertFalse(oldBaseTime >= newBaseTime)
	    XCTAssertTrue(newBaseTime >= oldBaseTime)

	    XCTAssertFalse(oldBaseTime > newBaseTime)
	    XCTAssertTrue(newBaseTime > oldBaseTime)
    }
}
