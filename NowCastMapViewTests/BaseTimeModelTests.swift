//
//  BaseTimeModelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/19/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest

@testable import NowCastMapView

class BaseTimeModelTests: BaseTestCase, BaseTimeModelDelegate {
	var baseTimeModel = BaseTimeModel()

	private var isFinished = false
	private var delegateCount = 0
	private var expectedResult: ComparisonResult? = nil

	override func setUp() {
		super.setUp()

		baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self

		isFinished = false
		delegateCount = 0
		expectedResult = nil
	}

	func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
		delegateCount += 1

		if baseTime != nil {
			isFinished = true
		}
	}

	func testFetch() {
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertTrue(isFinished)
	}

	func testConcurrentFetchRequests() {
		baseTimeModel.fetch()
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertTrue(isFinished)
		XCTAssertEqual(delegateCount, 1)
	}

	func testFetchInterval() {
		let interval: TimeInterval = 3
		baseTimeModel.fetchInterval = interval

		// first notification
		wait(seconds: interval + 1)
		XCTAssertTrue(isFinished)
		XCTAssertEqual(delegateCount, 1)

		baseTimeModel.current = nil
		XCTAssertEqual(delegateCount, 2)

		// second notification
		wait(seconds: interval + 3)
		XCTAssertEqual(delegateCount, 3)
	}
}
