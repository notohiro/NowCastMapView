//
//  NowCastBaseTimeManagerTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/19/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest

class NowCastBaseTimeManagersTests: AmeBaseTestCase {
	let baseTimeManager = NowCastBaseTimeManager.sharedManager
	private var isFinished = false
	private var expectedResult: NSComparisonResult? = nil

	func removeCache() {
		baseTimeManager.removeCache()
		waitForSeconds(0.5)
	}

	func testRemoveCache() {
		removeCache()

		// set cache
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			NowCastBaseTimeManager.sharedManager.saveBaseTime(baseTime)
		}
		else { XCTFail() }

		XCTAssertNotNil(baseTimeManager.lastSavedBaseTime)
		removeCache()
		XCTAssertNil(baseTimeManager.lastSavedBaseTime)
	}

	func testFetchWithoutCache() {
		removeCache()

		// this is new baseTime
		let firstExp = expectationWithDescription(description)
		expectationForNotification(NowCastBaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			if let userInfo = notification.userInfo {
				if let object = userInfo[NowCastBaseTimeManager.Notification.object] as? NowCastBaseTimeManagerNotificationObject {
					if object.fetchResult == .OrderedAscending { firstExp.fulfill() }
					else { XCTFail() }
				}
				else { XCTFail() }
			}
			else { XCTFail() }
			return true
		}

		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)

		// this is same as previous fetched
		let secondExp = expectationWithDescription(description)
		expectationForNotification(NowCastBaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			if let userInfo = notification.userInfo {
				if let object = userInfo[NowCastBaseTimeManager.Notification.object] as? NowCastBaseTimeManagerNotificationObject {
					if object.fetchResult == .OrderedSame { secondExp.fulfill() }
					else { XCTFail() }
				}
				else { XCTFail() }
			}
			else { XCTFail() }
			return true
		}

		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)
	}

	func testFetchWithCache() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			NowCastBaseTimeManager.sharedManager.saveBaseTime(baseTime)
		}
		else { XCTFail() }

		// test .OrderedAscending
		let firstExp = expectationWithDescription(description)
		expectationForNotification(NowCastBaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			if let userInfo = notification.userInfo {
				if let object = userInfo[NowCastBaseTimeManager.Notification.object] as? NowCastBaseTimeManagerNotificationObject {
					if object.fetchResult == .OrderedAscending { firstExp.fulfill() }
					else { XCTFail() }
				}
				else { XCTFail() }
			}
			else { XCTFail() }
			return true
		}

		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)
	}

	func testConcurrentFetchRequests() {
		removeCache()
		
		let firstExp = expectationWithDescription(description)
		expectationForNotification(NowCastBaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			if let userInfo = notification.userInfo {
				if let object = userInfo[NowCastBaseTimeManager.Notification.object] as? NowCastBaseTimeManagerNotificationObject {
					if object.fetchResult == .OrderedAscending { firstExp.fulfill() }
					else { XCTFail() }
				}
				else { XCTFail() }
			}
			else { XCTFail() }
			return true
		}

		baseTimeManager.fetch()
		baseTimeManager.fetch()
		waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)

		waitForSeconds(1.0)
	}

	func testFetchInterval() {
		removeCache()

		let interval: NSTimeInterval = 3
		NowCastBaseTimeManager.sharedManager.fetchInterval = interval

		// first notification
		expectationForNotification(NowCastBaseTimeManager.Notification.name, object: nil, handler: nil)
		waitForExpectationsWithTimeout(interval+1, handler: nil)

		// second notification
		expectationForNotification(NowCastBaseTimeManager.Notification.name, object: nil, handler: nil)
		waitForExpectationsWithTimeout(interval+1, handler: nil)

		baseTimeManager.fetchInterval = 0
	}
}
