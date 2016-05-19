//
//  NowCastImageManagerTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 3/13/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

class NowCastImageManagerTests: XCTestCase {
	let imageManager = NowCastImageManager.sharedManager

	func testNCZoomLevel() {
		XCTAssertEqual(NCZoomLevel.NCZoomLevel2.rawValue, 4)
		XCTAssertEqual(NCZoomLevel.NCZoomLevel4.rawValue, 16)
		XCTAssertEqual(NCZoomLevel.NCZoomLevel6.rawValue, 64)

		XCTAssertEqual(NCZoomLevel(zoomScale: 0.000489), NCZoomLevel.NCZoomLevel6)
		XCTAssertEqual(NCZoomLevel(zoomScale: 0.000488), NCZoomLevel.NCZoomLevel4)
		XCTAssertEqual(NCZoomLevel(zoomScale: 0.000123), NCZoomLevel.NCZoomLevel4)
		XCTAssertEqual(NCZoomLevel(zoomScale: 0.000122), NCZoomLevel.NCZoomLevel2)

		XCTAssertEqual(NCZoomLevel.NCZoomLevel2.toURLPrefix(), "zoom2")
		XCTAssertEqual(NCZoomLevel.NCZoomLevel4.toURLPrefix(), "zoom4")
		XCTAssertEqual(NCZoomLevel.NCZoomLevel6.toURLPrefix(), "zoom6")
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
}