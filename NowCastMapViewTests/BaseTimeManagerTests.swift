//
//  BaseTimeManagerTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/19/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest

class BaseTimeManagersTests: BaseTestCase {
	let baseTimeManager = BaseTimeManager.sharedManager
	private var isFinished = false
	private var expectedResult: NSComparisonResult? = nil

	func removeCache() {
		baseTimeManager.removeCache()
		waitForSeconds(0.5)
	}

	func testRemoveCache() {
		removeCache()

		// set cache
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }
		BaseTimeManager.sharedManager.saveBaseTime(baseTime)

		XCTAssertNotNil(baseTimeManager.lastSavedBaseTime)
		removeCache()
		XCTAssertNil(baseTimeManager.lastSavedBaseTime)
	}

	func testFetchWithoutCache() {
		removeCache()

		// this is new baseTime
		let firstExp = expectationWithDescription(description)
		expectationForNotification(BaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			guard let object = notification.userInfo?[BaseTimeManager.Notification.object] as? BaseTimeManagerNotificationObject else {
				XCTFail()
				return true
			}

			if object.fetchResult == .OrderedAscending { firstExp.fulfill() }

			return true
		}

		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)

		// this is same as previous fetched
		let secondExp = expectationWithDescription(description)
		expectationForNotification(BaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			guard let object = notification.userInfo?[BaseTimeManager.Notification.object] as? BaseTimeManagerNotificationObject else {
				XCTFail()
				return true
			}

			if object.fetchResult == .OrderedSame { secondExp.fulfill() }

			return true
		}

		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)
	}

	func testFetchWithCache() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			BaseTimeManager.sharedManager.saveBaseTime(baseTime)
		} else {
			XCTFail()
		}

		// test .OrderedAscending
		let firstExp = expectationWithDescription(description)
		expectationForNotification(BaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			guard let object = notification.userInfo?[BaseTimeManager.Notification.object] as? BaseTimeManagerNotificationObject else {
				XCTFail()
				return true
			}

			if object.fetchResult == .OrderedAscending { firstExp.fulfill() }

			return true
		}

		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)
	}

	func testConcurrentFetchRequests() {
		removeCache()

		let firstExp = expectationWithDescription(description)
		expectationForNotification(BaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			guard let object = notification.userInfo?[BaseTimeManager.Notification.object] as? BaseTimeManagerNotificationObject else {
				XCTFail()
				return true
			}

			if object.fetchResult == .OrderedAscending { firstExp.fulfill() }

			return true
		}

		baseTimeManager.fetch()
		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)

		waitForSeconds(1.0)
	}

	func testFetchInterval() {
		removeCache()

		let interval: NSTimeInterval = 3
		BaseTimeManager.sharedManager.fetchInterval = interval

		// first notification
		expectationForNotification(BaseTimeManager.Notification.name, object: nil, handler: nil)
		waitForExpectationsWithTimeout(interval+1, handler: nil)

		// second notification
		expectationForNotification(BaseTimeManager.Notification.name, object: nil, handler: nil)
		waitForExpectationsWithTimeout(interval+1, handler: nil)

		baseTimeManager.fetchInterval = 0
	}
}
