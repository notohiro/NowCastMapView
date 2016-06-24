//
//  RainLevelsTest.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/7/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

class RainLevelTest: XCTestCase {
	func testRainLevel() {
		// RainLevel = 0 to 8
		for rainLevelColor in rainLevelColors {
			let rainLevel = RainLevel(color: rainLevelColor.color)
			XCTAssertEqual(rainLevel.level, rainLevelColor.level)
			// except in case of RGBA(0, 0, 0, 0)
			if rainLevelColor.color.alpha != 0 { XCTAssertEqual(rainLevel.toRGBA255()!, rainLevelColor.color) }
		}

		// RainLevel = levelNotDetected
		let rainLevel = RainLevel(color: RGBA255(red: 1, green: 1, blue: 1, alpha: 1))
		XCTAssertNil(rainLevel.toRGBA255())
		XCTAssertNil(rainLevel.toUIColor())
	}
}

class RainLevelsTest: BaseTestCase {
	override func setUp() {
		super.setUp()
		ImageManager.sharedManager.sharedImageCache.removeAllObjects()
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.5))
	}

	func testRainLevelsWithCacheAndHandler() {
		let colorPoints: [(point: CGPoint, expectedRainLevel: Int)] = [
			(CGPoint.init(x: 0, y: 2), 0),
			(CGPoint.init(x: 0, y: 0), 1),
			(CGPoint.init(x: 8, y: 15), 2),
			(CGPoint.init(x: 89, y: 104), 3),
			(CGPoint.init(x: 86, y: 106), 4),
			(CGPoint.init(x: 86, y: 111), 5),
			(CGPoint.init(x: 89, y: 114), 6),
			(CGPoint.init(x: 90, y: 114), 7),
			(CGPoint.init(x: 87, y: 116), 8)]

		for point in colorPoints {
			guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

			let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
			let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
			let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent)

			guard let coordinate = image?.coordinate(atPoint: point.point) else { XCTFail(); return }

			let exp = expectationWithDescription("testRainLevelsWithCacheAndHandler")
			let _ = RainLevels(baseTime: baseTime, coordinate: coordinate) { (rainLevels: RainLevels, error: NSError?) -> Void in
				XCTAssertEqual(rainLevels.rainLevel(atBaseTimeIndex: 0)?.level ?? -1, point.expectedRainLevel)
				exp.fulfill()
			}

			waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)

		}
	}

	func testRainLevelsWithCacheFor0000() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile2", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
		let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent)

		guard let coordinate = image?.coordinate(atPoint: CGPoint.init(x: 0, y: 0)) else { XCTFail(); return }

		let exp = expectationWithDescription("testRainLevelsWithCacheAndHandler")
		let _ = RainLevels(baseTime: baseTime, coordinate: coordinate) { (rainLevels: RainLevels, error: NSError?) -> Void in
			XCTAssertEqual(rainLevels.rainLevel(atBaseTimeIndex: 0)?.level ?? -1, 0)
			exp.fulfill()
		}

		waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)
	}

	func testRainLevelsWithCacheForInvalidCoordinate() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNil(RainLevels(baseTime: baseTime, coordinate: CLLocationCoordinate2DMake(62, 99), completionHandler: nil))
	}

	func testRainLevelsWithHandlerWithoutCache() {
		// fetch latest BaseTime
		var baseTime: BaseTime?

		expectationForNotification(BaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			guard let object = notification.userInfo?[BaseTimeManager.Notification.object] as? BaseTimeManagerNotificationObject else {
				XCTFail()
				return true
			}
			baseTime = object.baseTime

			return true
		}

		BaseTimeManager.sharedManager.fetch()
		waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)

		// fetch latest RainLevels
		let exp = expectationWithDescription("testRainLevelsWithoutCache")

		expectationForNotification(RainLevels.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			guard let rainLevels = notification.userInfo?[RainLevels.Notification.object] as? RainLevels else { XCTFail(); return true }

			XCTAssertNotNil(rainLevels.rainLevel(atBaseTimeIndex: 0))
			XCTAssertNil(rainLevels.rainLevel(atBaseTimeIndex: 1000))

			return true
		}

		weak var weakRainLevels: RainLevels?
		autoreleasepool {
			guard let baseTime = baseTime else { XCTFail(); return }

			print("\(baseTime.description)")
			var rainLevels = RainLevels(baseTime: baseTime, coordinate: CLLocationCoordinate2DMake(37.785834, 139.651421)) {
				(rainLevels: RainLevels, error: NSError?) -> Void in
				XCTAssertNotEqual(rainLevels.rainLevels.count, 0)
				exp.fulfill()
			}
			print(rainLevels?.baseTime.description)

			XCTAssertNotNil(rainLevels)
			XCTAssertNil(rainLevels!.rainLevel(atBaseTimeIndex: 0))
			weakRainLevels = rainLevels

			waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)

			rainLevels = nil
		}

		XCTAssertNil(weakRainLevels)
	}

	func testRainLevelsWithInvalidBaseTimeForError() {
		guard let baseTime = getBaseTimeFrom("InvalidBaseTime") else { XCTFail(); return }

		let exp = expectationWithDescription("testRainLevelsWithInvalidBaseTimeForError")

		expectationForNotification(RainLevels.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
			guard let rainLevels = notification.userInfo?[RainLevels.Notification.object] as? RainLevels else { XCTFail(); return true }

			XCTAssertEqual(rainLevels.state, RainLevelsState.completedWithError)

			return true
		}

		weak var weakRainLevels: RainLevels?
		autoreleasepool {
			var rainLevels = RainLevels(baseTime: baseTime, coordinate: CLLocationCoordinate2DMake(37.785834, 139.651421)) {
				(rainLevels: RainLevels, error: NSError?) -> Void in
				XCTAssertEqual(rainLevels.rainLevels.count, 0)
				exp.fulfill()
			}

			XCTAssertNotNil(rainLevels)
			XCTAssertNil(rainLevels?.rainLevel(atBaseTimeIndex: 0))
			weakRainLevels = rainLevels

			waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)

			rainLevels = nil
		}

		XCTAssertNil(weakRainLevels)
	}
}
