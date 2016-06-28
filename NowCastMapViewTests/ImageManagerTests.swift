//
//  ImageManagerTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 3/13/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

class ImageManagerTests: BaseTestCase {
	let imageManager = ImageManager.sharedManager
	var imageFetchedCount = 0

	override func setUp() {
		super.setUp()
		imageFetchedCount = 0
	}

	func testZoomLevel() {
		XCTAssertEqual(ZoomLevel.level2.rawValue, 4)
		XCTAssertEqual(ZoomLevel.level4.rawValue, 16)
		XCTAssertEqual(ZoomLevel.level6.rawValue, 64)

		XCTAssertEqual(ZoomLevel(zoomScale: 0.000489), ZoomLevel.level6)
		XCTAssertEqual(ZoomLevel(zoomScale: 0.000488), ZoomLevel.level4)
		XCTAssertEqual(ZoomLevel(zoomScale: 0.000123), ZoomLevel.level4)
		XCTAssertEqual(ZoomLevel(zoomScale: 0.000122), ZoomLevel.level2)

		XCTAssertEqual(ZoomLevel.level2.toURLPrefix(), "zoom2")
		XCTAssertEqual(ZoomLevel.level4.toURLPrefix(), "zoom4")
		XCTAssertEqual(ZoomLevel.level6.toURLPrefix(), "zoom6")
	}

	func makeMapRect(originLatitude originLatitude: Double, originLongitude: Double, terminalLatitude: Double, terminalLongitude: Double) -> MKMapRect {
		// MKMapPoint, MKMapSize of origin, terminal
		let origin = MKMapPointForCoordinate(CLLocationCoordinate2DMake(originLatitude, originLongitude))
		let terminal = MKMapPointForCoordinate(CLLocationCoordinate2DMake(terminalLatitude, terminalLongitude))
		let size = MKMapSizeMake(terminal.x - origin.x, terminal.y - origin.y)

		// MKMapRect
		return MKMapRectMake(origin.x, origin.y, size.width, size.height)
	}

	func testIsServiceAvailableInMapRect() {
		let mapRectOutsideService = makeMapRect(originLatitude: 5, originLongitude: 150, terminalLatitude: 2, terminalLongitude: 152)
		XCTAssertFalse(imageManager.isServiceAvailable(inMapRect: mapRectOutsideService))

		let mapRectOverlapped = makeMapRect(originLatitude: 60, originLongitude: 90, terminalLatitude: 5, terminalLongitude: 110)
		XCTAssertTrue(imageManager.isServiceAvailable(inMapRect: mapRectOverlapped))

		let mapRectInsideService = makeMapRect(originLatitude: 60, originLongitude: 110, terminalLatitude: 59, terminalLongitude: 120)
		XCTAssertTrue(imageManager.isServiceAvailable(inMapRect: mapRectInsideService))
	}

	func testIsServiceAvailableAtCoordinate() {
		let coordinateInsideService = CLLocationCoordinate2DMake(60, 101)
		XCTAssertTrue(imageManager.isServiceAvailable(atCoordinate: coordinateInsideService))

		let coordinateOutsideService = CLLocationCoordinate2DMake(62, 99)
		XCTAssertFalse(imageManager.isServiceAvailable(atCoordinate: coordinateOutsideService))
	}

	func testPerformanceImages() {
		removeImageCache()

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

		// MKMapRect
		let origin = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude))
		let terminal = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude))
		let size = MKMapSizeMake(terminal.x - origin.x, terminal.y - origin.y)
		let mapRect = MKMapRectMake(origin.x, origin.y, size.width, size.height)

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(ImageManagerTests.newImageFetched(_:)), name: ImageManager.Notification.name, object: nil)

		self.measureBlock {
			guard let baseTime = baseTime else { XCTFail(); return }
			let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)

			let zoomScale = ZoomLevel.MKZoomScaleForLevel4
			let images = self.imageManager.images(inMapRect: mapRect, zoomScale: zoomScale, baseTimeContext: baseTimeContext, priority: .High)

			print("\(images.count)")

			while images.count != self.imageFetchedCount {
				let wait: NSTimeInterval = 0.01
				print("\(self.imageFetchedCount)")
				NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: wait))
			}
		}
	}

//	func testCancel() {
//		removeImageCache()
//
//		var baseTime: BaseTime?
//
//		expectationForNotification(BaseTimeManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
//			guard let object = notification.userInfo?[BaseTimeManager.Notification.object] as? BaseTimeManagerNotificationObject else {
//				XCTFail()
//				return true
//			}
//			baseTime = object.baseTime
//
//			return true
//		}
//
//		BaseTimeManager.sharedManager.fetch()
//
//		waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)
//
//		// MKMapRect
//		let origin = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude))
//		let terminal = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude))
//		let size = MKMapSizeMake(terminal.x - origin.x, terminal.y - origin.y)
//		let mapRect = MKMapRectMake(origin.x, origin.y, size.width, size.height)
//
//		if let baseTime = baseTime {
//			let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
//
//			let zoomScale = ZoomLevel.MKZoomScaleForLevel4
//			let images = self.imageManager.images(inMapRect: mapRect, zoomScale: zoomScale, baseTimeContext: baseTimeContext, priority: .Default)
//
//			let grobalQueue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
//
//			print("\(images.count)")
//			print("\(imageManager.imagePool.count)")
//
//			dispatch_sync(grobalQueue, {
//				let wait: NSTimeInterval = 1
//				NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: wait))
//			})
//
//			self.imageManager.cancelImageRequestsPriorityLessThan(.High)
//			print("\(imageManager.imagePool.count)")
//
//			dispatch_sync(grobalQueue, {
//				let wait: NSTimeInterval = 3
//				NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: wait))
//			})
//
//			print("\(imageManager.imagePool.count)")
//		} else {
//			XCTFail()
//		}
//	}

	func newImageFetched(notification: NSNotification) {
		imageFetchedCount += 1
	}
}
