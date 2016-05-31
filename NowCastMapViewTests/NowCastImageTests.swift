//
//  NowCastImageTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/10/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

class NowCastImageTests: NowCastBaseTestCase {
	override func setUp() {
		super.setUp()
		removeImageCache()
	}

	func testImageURL() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))

			let urlAtIndex0 = NowCastImage.imageURL(forLatitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0)
			XCTAssertEqual(urlAtIndex0?.absoluteString, "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200225/201509200225/zoom6/0_0.png")

			let urlAtPast = NowCastImage.imageURL(forLatitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: -1)
			XCTAssertEqual(urlAtPast?.absoluteString, "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200220/201509200220/zoom6/0_0.png")

			let urlAtFuture = NowCastImage.imageURL(forLatitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 1)
			XCTAssertEqual(urlAtFuture?.absoluteString, "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200225/201509200230/zoom6/0_0.png")
		}
		else { XCTFail() }
	}

	func testImageNumbers() {
		let coordinateAtRtightBottomOf00 = CLLocationCoordinate2DMake(47.6, 117.4)
		let imageNumbersOf00 = NowCastImage.imageNumbers(forCoordinate: coordinateAtRtightBottomOf00, zoomLevel: .NCZoomLevel2)
		XCTAssertEqual(imageNumbersOf00.latitudeNumber, 0)
		XCTAssertEqual(imageNumbersOf00.longitudeNumber, 0)

		let coordinateAtRtightBottomOf11 = CLLocationCoordinate2DMake(47.5, 117.5)
		let imageNumbersOf11 = NowCastImage.imageNumbers(forCoordinate: coordinateAtRtightBottomOf11, zoomLevel: .NCZoomLevel2)
		XCTAssertEqual(imageNumbersOf11.latitudeNumber, 1)
		XCTAssertEqual(imageNumbersOf11.longitudeNumber, 1)

	}

	func testCoordinates() {
		let coordinatesOf00 = NowCastImage.coordinates(forlatitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel2)
		XCTAssertEqual(coordinatesOf00.origin.latitude, 61.0)
		XCTAssertEqual(coordinatesOf00.origin.longitude, 100.0)

		let coordinatesOf11 = NowCastImage.coordinates(forlatitudeNumber: 1, longitudeNumber: 1, zoomLevel: .NCZoomLevel2)
		XCTAssertEqual(coordinatesOf11.origin.latitude, 47.5)
		XCTAssertEqual(coordinatesOf11.origin.longitude, 117.5)
	}

	func testInitWithoutCache() {
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

		weak var weakImage: NowCastImage?
		autoreleasepool {
			if let aBaseTime = baseTime {
				expectationForNotification(NowCastImageManager.Notification.name, object: nil) { (notification: NSNotification) -> Bool in
					if let userInfo = notification.userInfo {
						if let object = userInfo[NowCastImageManager.Notification.object] as? NowCastImage {
							XCTAssertNotNil(object.image)
						}
						else { XCTFail() }
					}
					else { XCTFail() }

					return true
				}

				let nowCastImage = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: aBaseTime, baseTimeIndex: 0, priority: NowCastDownloadPriorityUrgent)
				weakImage = nowCastImage
				XCTAssertNil(nowCastImage!.image)
			}
			else { XCTFail() }

			waitForExpectationsWithTimeout(SecondsForTimeout, handler: nil)
		}

		XCTAssertNil(weakImage)
	}

	func testMapRect() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))
			if let image = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: NowCastDownloadPriorityUrgent) {
				let mapRect = image.mapRect
				let origin = MKCoordinateForMapPoint(mapRect.origin)
				XCTAssertEqual(origin.latitude, 61)
				XCTAssertEqual(origin.longitude, 100)

				let terminal = MKCoordinateForMapPoint(MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height))


				let handler = NSDecimalNumberHandler(roundingMode: .RoundPlain, scale: 5, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: true)
				let latitude = NSDecimalNumber(double: terminal.latitude)
				let roundedLatitude = latitude.decimalNumberByRoundingAccordingToBehavior(handler)
				let longitude = NSDecimalNumber(double: terminal.longitude)
				let roundedLongitude = longitude.decimalNumberByRoundingAccordingToBehavior(handler)
				XCTAssertEqual(roundedLatitude, 61 - image.deltas.latitudeDelta)
				XCTAssertEqual(roundedLongitude, 100 + image.deltas.longitudeDelta)
			}
			else { XCTFail() }
		}
		else { XCTFail() }
	}

	func testIsOnImage() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))
			if let image = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: NowCastDownloadPriorityUrgent) {
				let coordinates = image.rectCoordinates
				XCTAssertTrue(image.isOnImage(forCoordinate: coordinates.origin))
				XCTAssertFalse(image.isOnImage(forCoordinate: CLLocationCoordinate2DMake(coordinates.origin.latitude, coordinates.terminal.longitude)))
				XCTAssertFalse(image.isOnImage(forCoordinate: CLLocationCoordinate2DMake(coordinates.terminal.latitude, coordinates.origin.longitude)))
				XCTAssertFalse(image.isOnImage(forCoordinate: coordinates.terminal))
			}
			else { XCTFail() }
		}
		else { XCTFail() }
	}

	func testColorAtCoordinate() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))
			if let image = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: NowCastDownloadPriorityUrgent) {
				if let color = image.color(atCoordinate: image.rectCoordinates.origin) {
					XCTAssertEqual(color.red, NowCastRainLevelColor1.color.red)
					XCTAssertEqual(color.green, NowCastRainLevelColor1.color.green)
					XCTAssertEqual(color.blue, NowCastRainLevelColor1.color.blue)
					XCTAssertEqual(color.alpha, NowCastRainLevelColor1.color.alpha)
				}
				else { XCTFail() }

				XCTAssertNil(image.color(atCoordinate: image.rectCoordinates.terminal))
			}
			else { XCTFail() }
		}
		else { XCTFail() }
	}

	func testPointAtCoordinate() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))
			if let image = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: NowCastDownloadPriorityUrgent) {
				if let originPoint = image.point(atCoordinate: image.rectCoordinates.origin) {
					XCTAssertEqual(originPoint, CGPointMake(0, 0))
				}
				else { XCTFail() }

				XCTAssertNil(image.point(atCoordinate: image.rectCoordinates.terminal))

				let middleLatitude = image.rectCoordinates.origin.latitude - (image.deltas.latitudeDelta / 2)
				let middleLongitude = image.rectCoordinates.origin.longitude + (image.deltas.longitudeDelta / 2)
				if let middlePoint = image.point(atCoordinate: CLLocationCoordinate2DMake(middleLatitude, middleLongitude)) {
					if let imageData = image.image {
						XCTAssertEqual(middlePoint, CGPointMake((imageData.size.width)/2, (imageData.size.height)/2))
					}
					else { XCTFail() }
				}
				else { XCTFail() }
			}
			else { XCTFail() }
		}
		else { XCTFail() }
	}

	func testPositionAtCoordinate() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))
			if let image = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: NowCastDownloadPriorityUrgent) {
				if let originPosition = image.position(atCoordinate: image.rectCoordinates.origin) {
					XCTAssertEqual(originPosition.latitudePosition, 0.0)
					XCTAssertEqual(originPosition.longitudePosition, 0.0)
				}
				else { XCTFail() }

				XCTAssertNil(image.position(atCoordinate: image.rectCoordinates.terminal))

				let middleLatitude = image.rectCoordinates.origin.latitude - (image.deltas.latitudeDelta / 2)
				let middleLongitude = image.rectCoordinates.origin.longitude + (image.deltas.longitudeDelta / 2)
				if let middlePotision = image.position(atCoordinate: CLLocationCoordinate2DMake(middleLatitude, middleLongitude)) {
					XCTAssertEqual(middlePotision.latitudePosition, 0.5)
					XCTAssertEqual(middlePotision.longitudePosition, 0.5)
				}
				else { XCTFail() }
			}
			else { XCTFail() }
		}
		else { XCTFail() }
	}

	// return coordinate for center of pixel
	func testCoordinateAtPoint() {
		if let baseTime = getBaseTimeFrom("OldBaseTime") {
			XCTAssertNotNil(setImageCache("tile", forBaseTime: baseTime))
			if let image = NowCastImage(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: 0, priority: NowCastDownloadPriorityUrgent) {
				if let originCoordinate = image.coordinate(atPoint: CGPointMake(0, 0)) {
					if let originPoint = image.point(atCoordinate: originCoordinate) {
						XCTAssertEqual(originPoint, CGPointMake(0, 0))
					}
					else { XCTFail() }
				}
				else { XCTFail() }

				if let imageData = image.image {
					if let terminalCoordinate = image.coordinate(atPoint: CGPointMake(imageData.size.width - 1, imageData.size.height - 1)) {
						if let terminalPoint = image.point(atCoordinate: terminalCoordinate) {
							XCTAssertEqual(terminalPoint, CGPointMake(imageData.size.width - 1, imageData.size.height - 1))
						}
						else { XCTFail() }
					}
					else { XCTFail() }

					XCTAssertNil(image.coordinate(atPoint: CGPointMake(-1, -1)))
					XCTAssertNil(image.coordinate(atPoint: CGPointMake(imageData.size.width, imageData.size.height)))
				}
			}
			else { XCTFail() }
		}
		else { XCTFail() }
	}
}
