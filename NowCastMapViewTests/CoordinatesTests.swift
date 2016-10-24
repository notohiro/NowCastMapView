//
//  CoordinatesTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/23.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import CoreLocation

@testable import NowCastMapView

class CoordinatesTests: XCTestCase {
	func testInit() {
		let coordinateAtRtightBottomOf00 = CLLocationCoordinate2DMake(47.6, 117.4)
		guard let modifiers00 = Tile.Modifiers(zoomLevel: .level2, coordinate: coordinateAtRtightBottomOf00) else { XCTFail(); return }
		let coordinates00 = Coordinates(modifiers: modifiers00)
		XCTAssertEqual(coordinates00.origin.latitude, 61.0)
		XCTAssertEqual(coordinates00.origin.longitude, 100.0)

		let coordinateAtRtightBottomOf11 = CLLocationCoordinate2DMake(47.5, 117.5)
		guard let modifiers11 = Tile.Modifiers(zoomLevel: .level2, coordinate: coordinateAtRtightBottomOf11) else { XCTFail(); return }
		let coordinates11 = Coordinates(modifiers: modifiers11)
		XCTAssertEqual(coordinates11.origin.latitude, 47.5)
		XCTAssertEqual(coordinates11.origin.longitude, 117.5)
	}
}
