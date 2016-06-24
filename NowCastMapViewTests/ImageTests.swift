//
//  ImageTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/10/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

class ImageTests: BaseTestCase {
	override func setUp() {
		super.setUp()
		removeImageCache()
	}

	func testURL() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		var baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)

		let urlAtIndex0 = Image.url(forImageContext: imageContext, baseTimeContext: baseTimeContext)
		XCTAssertEqual(urlAtIndex0?.absoluteString, "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200225/201509200225/zoom6/0_0.png")

		baseTimeContext.index = -1
		let urlAtPast = Image.url(forImageContext: imageContext, baseTimeContext: baseTimeContext)
		XCTAssertEqual(urlAtPast?.absoluteString, "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200220/201509200220/zoom6/0_0.png")

		baseTimeContext.index = 1
		let urlAtFuture = Image.url(forImageContext: imageContext, baseTimeContext: baseTimeContext)
		XCTAssertEqual(urlAtFuture?.absoluteString, "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200225/201509200230/zoom6/0_0.png")
	}

	func testNumbers() {
		let coordinateAtRtightBottomOf00 = CLLocationCoordinate2DMake(47.6, 117.4)
		let imageNumbersOf00 = Image.numbers(forCoordinate: coordinateAtRtightBottomOf00, zoomLevel: .level2)
		XCTAssertEqual(imageNumbersOf00.latitudeNumber, 0)
		XCTAssertEqual(imageNumbersOf00.longitudeNumber, 0)

		let coordinateAtRtightBottomOf11 = CLLocationCoordinate2DMake(47.5, 117.5)
		let imageNumbersOf11 = Image.numbers(forCoordinate: coordinateAtRtightBottomOf11, zoomLevel: .level2)
		XCTAssertEqual(imageNumbersOf11.latitudeNumber, 1)
		XCTAssertEqual(imageNumbersOf11.longitudeNumber, 1)
	}

	func testCoordinates() {
		let contextOf00 = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level2)
		let coordinatesOf00 = Image.coordinates(forImageContext: contextOf00)
		XCTAssertEqual(coordinatesOf00.origin.latitude, 61.0)
		XCTAssertEqual(coordinatesOf00.origin.longitude, 100.0)

		let contextOf11 = ImageContext(latitudeNumber: 1, longitudeNumber: 1, zoomLevel: .level2)
		let coordinatesOf11 = Image.coordinates(forImageContext: contextOf11)
		XCTAssertEqual(coordinatesOf11.origin.latitude, 47.5)
		XCTAssertEqual(coordinatesOf11.origin.longitude, 117.5)
	}

	func testInitWithoutCache() {
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

		weak var weakImage: Image?
		autoreleasepool {
			guard let baseTime = baseTime else { XCTFail(); return }

			expectationForNotification(ImageManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
				guard let image = notification.userInfo?[ImageManager.Notification.object] as? Image else { XCTFail(); return true }

				XCTAssertNotNil(image.imageData)

				return true
			}

			let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
			let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
			let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent)
			weakImage = image
			XCTAssertNil(image!.imageData)

			waitForExpectationsWithTimeout(secondsForTimeout, handler: nil)
		}

		XCTAssertNil(weakImage)
	}

	func testMapRect() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
		guard let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent) else { XCTFail(); return }

		let mapRect = image.mapRect
		let origin = MKCoordinateForMapPoint(mapRect.origin)
		XCTAssertEqual(origin.latitude, 61)
		XCTAssertEqual(origin.longitude, 100)

		let terminal = MKCoordinateForMapPoint(MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height))


		let handler = NSDecimalNumberHandler(roundingMode: .RoundPlain,
		                                     scale: 5,
		                                     raiseOnExactness: false,
		                                     raiseOnOverflow: false,
		                                     raiseOnUnderflow: false,
		                                     raiseOnDivideByZero: true)
		let latitude = NSDecimalNumber(double: terminal.latitude)
		let roundedLatitude = latitude.decimalNumberByRoundingAccordingToBehavior(handler)
		let longitude = NSDecimalNumber(double: terminal.longitude)
		let roundedLongitude = longitude.decimalNumberByRoundingAccordingToBehavior(handler)
		XCTAssertEqual(roundedLatitude, 61 - image.deltas.latitudeDelta)
		XCTAssertEqual(roundedLongitude, 100 + image.deltas.longitudeDelta)
	}

	func testContains() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
		guard let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent) else { XCTFail(); return }

		let coordinates = image.rectCoordinates
		XCTAssertTrue(image.contains(coordinates.origin))
		XCTAssertFalse(image.contains(CLLocationCoordinate2DMake(coordinates.origin.latitude, coordinates.terminal.longitude)))
		XCTAssertFalse(image.contains(CLLocationCoordinate2DMake(coordinates.terminal.latitude, coordinates.origin.longitude)))
		XCTAssertFalse(image.contains(coordinates.terminal))
	}

	func testColorAtCoordinate() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
		guard let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent) else { XCTFail(); return }
		guard let color = image.color(atCoordinate: image.rectCoordinates.origin) else { XCTFail(); return }

		XCTAssertEqual(color.red, rainLevelColor1.color.red)
		XCTAssertEqual(color.green, rainLevelColor1.color.green)
		XCTAssertEqual(color.blue, rainLevelColor1.color.blue)
		XCTAssertEqual(color.alpha, rainLevelColor1.color.alpha)

		XCTAssertNil(image.color(atCoordinate: image.rectCoordinates.terminal))
	}

	func testPointAtCoordinate() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
		guard let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent) else { XCTFail(); return }

		guard let originPoint = image.point(atCoordinate: image.rectCoordinates.origin) else { XCTFail(); return }
		XCTAssertEqual(originPoint, CGPoint.init(x: 0, y: 0))

		XCTAssertNil(image.point(atCoordinate: image.rectCoordinates.terminal))

		let middleLatitude = image.rectCoordinates.origin.latitude - (image.deltas.latitudeDelta / 2)
		let middleLongitude = image.rectCoordinates.origin.longitude + (image.deltas.longitudeDelta / 2)
		guard let middlePoint = image.point(atCoordinate: CLLocationCoordinate2DMake(middleLatitude, middleLongitude)) else { XCTFail(); return }
		guard let imageData = image.imageData else { XCTFail(); return }

		XCTAssertEqual(middlePoint, CGPoint.init(x: (imageData.size.width)/2, y: (imageData.size.height)/2))
	}

	func testPositionAtCoordinate() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
		guard let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent) else { XCTFail(); return }

		guard let originPosition = image.position(atCoordinate: image.rectCoordinates.origin) else { XCTFail(); return }

		XCTAssertEqual(originPosition.latitudePosition, 0.0)
		XCTAssertEqual(originPosition.longitudePosition, 0.0)

		XCTAssertNil(image.position(atCoordinate: image.rectCoordinates.terminal))

		let middleLatitude = image.rectCoordinates.origin.latitude - (image.deltas.latitudeDelta / 2)
		let middleLongitude = image.rectCoordinates.origin.longitude + (image.deltas.longitudeDelta / 2)
		guard let middlePotision = image.position(atCoordinate: CLLocationCoordinate2DMake(middleLatitude, middleLongitude)) else { XCTFail(); return }

		XCTAssertEqual(middlePotision.latitudePosition, 0.5)
		XCTAssertEqual(middlePotision.longitudePosition, 0.5)
	}

	// return coordinate for center of pixel
	func testCoordinateAtPoint() {
		guard let baseTime = getBaseTimeFrom("OldBaseTime") else { XCTFail(); return }

		XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

		let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
		let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: 0)
		guard let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: .Urgent) else { XCTFail(); return }

		guard let originCoordinate = image.coordinate(atPoint: CGPoint.init(x: 0, y: 0)) else { XCTFail(); return }
		guard let originPoint = image.point(atCoordinate: originCoordinate) else { XCTFail(); return }
		XCTAssertEqual(originPoint, CGPoint.init(x: 0, y: 0))

		guard let imageData = image.imageData else { XCTFail(); return }
		guard let terminalCoordinate = image.coordinate(atPoint: CGPoint.init(x: imageData.size.width - 1, y: imageData.size.height - 1)) else {
			XCTFail()
			return
		}
		guard let terminalPoint = image.point(atCoordinate: terminalCoordinate) else { XCTFail(); return }

		XCTAssertEqual(terminalPoint, CGPoint.init(x: imageData.size.width - 1, y: imageData.size.height - 1))
		XCTAssertNil(image.coordinate(atPoint: CGPoint.init(x: -1, y: -1)))
		XCTAssertNil(image.coordinate(atPoint: CGPoint.init(x: imageData.size.width, y: imageData.size.height)))

	}
}
