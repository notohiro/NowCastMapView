//
//  NowCastRainLevelsTest.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/7/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

class NowCastRainLevelTest: XCTestCase {
	func testNowCastRainLevel() {
		// NowCastRainLevel = 0 to 8
		for rainLevelColor in NowCastRainLevelColors {
			let rainLevel = NowCastRainLevel(color: rainLevelColor.color)
			XCTAssertEqual(rainLevel.level, rainLevelColor.level)
			// except in case of RGBA(0, 0, 0, 0)
			if rainLevelColor.color.alpha != 0 { XCTAssertEqual(rainLevel.toRGBA255()!, rainLevelColor.color) }
		}

		// NowCastRainLevel = levelNotDetected
		let rainLevel = NowCastRainLevel(color: RGBA255(red: 1, green: 1, blue: 1, alpha: 1))
		XCTAssertNil(rainLevel.toRGBA255())
		XCTAssertNil(rainLevel.toUIColor())
	}
}

class NowCastRainLevelsTest: AmeBaseTestCase {
	override func setUp() {
		super.setUp()
		NowCastImageManager.sharedManager.sharedImageCache.removeAllObjects()
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.5))
	}

	func testRainLevelsWithCacheAndHandler() {
		let colorPoints: [(point: CGPoint, expectedRainLevel: Int)] = [
			(CGPointMake( 0,   2), 0),
			(CGPointMake( 0,   0), 1),
			(CGPointMake( 8,  15), 2),
			(CGPointMake(89, 104), 3),
			(CGPointMake(86, 106), 4),
			(CGPointMake(86, 111), 5),
			(CGPointMake(89, 114), 6),
			(CGPointMake(90, 114), 7),
			(CGPointMake(87, 116), 8)]

		for point in colorPoints {
			if let baseTime = getBaseTimeFrom("OldBaseTime") {
				XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

				let coordinate = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: 0)
					.flatMap { $0.coordinate(atPoint: point.point) }
				if let coordinate = coordinate {
					let exp = expectationWithDescription("testRainLevelsWithCacheAndHandler")
					let _ = NowCastRainLevels(baseTime: baseTime, coordinate: coordinate) { (rainLevels: NowCastRainLevels, error: NSError?) -> Void in
						XCTAssertEqual(rainLevels.rainLevel(atBaseTimeIndex: 0)?.level ?? -1, point.expectedRainLevel)
						exp.fulfill()
					}

					waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)
				}
				else { XCTFail() }
			}
			else { XCTFail() }
		}
	}

	func testRainLevelsWithCacheFor0000() {
		let baseTime = getBaseTimeFrom("OldBaseTime")

		if let baseTime = baseTime {
			XCTAssertNotNil(setImageCache("tile2", forBaseTime: baseTime))

			let coordinate = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: 0)
				.flatMap { $0.coordinate(atPoint: CGPointMake(0, 0)) }
			if let coordinate = coordinate {
				let exp = expectationWithDescription("testRainLevelsWithCacheAndHandler")
				let _ = NowCastRainLevels(baseTime: baseTime, coordinate: coordinate) { (rainLevels: NowCastRainLevels, error: NSError?) -> Void in
					XCTAssertEqual(rainLevels.rainLevel(atBaseTimeIndex: 0)?.level ?? -1, 0)
					exp.fulfill()
				}

				waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)
			}
			else { XCTFail() }
		}
		else { XCTFail() }
	}

	func testRainLevelsWithCacheForInvalidCoordinate() {
		let baseTime = getBaseTimeFrom("OldBaseTime")

		if let baseTime = baseTime {
			XCTAssertNil(NowCastRainLevels(baseTime: baseTime, coordinate: CLLocationCoordinate2DMake(62, 99), completionHandler: nil))
		}
		else { XCTFail() }
	}

	func testRainLevelsWithHandlerWithoutCache() {
		// fetch latest NowCastBaseTime
		var baseTime: NowCastBaseTime?

		expectationForNotification(NowCastBaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			if let userInfo = notification.userInfo {
				if let object = userInfo[NowCastBaseTimeManager.Notification.object] as? NowCastBaseTimeManagerNotificationObject {
					baseTime = object.baseTime
				}
				else { XCTFail() }
			}
			else { XCTFail() }

			return true
		}

		NowCastBaseTimeManager.sharedManager.fetch()
		waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)

		// fetch latest NowCastRainLevels
		let exp = expectationWithDescription("testRainLevelsWithoutCache")

		expectationForNotification(NowCastRainLevels.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			if let userInfo = notification.userInfo {
				if let object = userInfo[NowCastRainLevels.Notification.object] as? NowCastRainLevels {
					XCTAssertNotNil(object.rainLevel(atBaseTimeIndex: 0))
					XCTAssertNil(object.rainLevel(atBaseTimeIndex: 1000))
				}
				else { XCTFail() }
			}
			else { XCTFail() }

			return true
		}

		weak var weakRainLevels: NowCastRainLevels?
		if let baseTime = baseTime {
			print("\(baseTime.description)")
			autoreleasepool {
				print("\(baseTime.description)")
				var rainLevels = NowCastRainLevels(baseTime: baseTime, coordinate: CLLocationCoordinate2DMake(37.785834, 139.651421)) {
					(rainLevels: NowCastRainLevels, error: NSError?) -> Void in
					XCTAssertNotEqual(rainLevels.rainLevels.count, 0)
					exp.fulfill()
				}
				print(rainLevels?.baseTime.description)

				XCTAssertNotNil(rainLevels)
				XCTAssertNil(rainLevels!.rainLevel(atBaseTimeIndex: 0))
				weakRainLevels = rainLevels

				waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)

				rainLevels = nil
			}
		}
		else { XCTFail() }

		XCTAssertNil(weakRainLevels)
	}

	func testRainLevelsWithInvalidBaseTimeForError() {
		let baseTime = getBaseTimeFrom("InvalidBaseTime")

		let exp = expectationWithDescription("testRainLevelsWithInvalidBaseTimeForError")

		expectationForNotification(NowCastRainLevels.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			if let userInfo = notification.userInfo {
				if let object = userInfo[NowCastRainLevels.Notification.object] as? NowCastRainLevels {
					XCTAssertEqual(object.state, NowCastRainLevelsState.completedWithError)
				}
				else { XCTFail() }
			}
			else { XCTFail() }

			return true
		}

		weak var weakRainLevels: NowCastRainLevels?
		if let baseTime = baseTime {
			autoreleasepool {
				var rainLevels = NowCastRainLevels(baseTime: baseTime, coordinate: CLLocationCoordinate2DMake(37.785834, 139.651421)) {
					(rainLevels: NowCastRainLevels, error: NSError?) -> Void in
					XCTAssertEqual(rainLevels.rainLevels.count, 0)
					exp.fulfill()
				}

				XCTAssertNotNil(rainLevels)
				XCTAssertNil(rainLevels?.rainLevel(atBaseTimeIndex: 0))
				weakRainLevels = rainLevels

				waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)

				rainLevels = nil
			}
		}
		else { XCTFail() }

		XCTAssertNil(weakRainLevels)
	}
}
