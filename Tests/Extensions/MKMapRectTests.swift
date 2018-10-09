//
//  MKMapRectTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/23.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import MapKit
import XCTest

@testable import NowCastMapView

class MKMapRectTests: BaseTestCase {
    func testInit() {
	    guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
	    let mapRect = MKMapRect(modifiers: modifiers)

	    let origin = mapRect.origin.coordinate
	    XCTAssertEqual(origin.latitude, 61)
	    XCTAssertEqual(origin.longitude, 100)

//	    let terminalPoint = MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height)
//	    let terminal = MKCoordinateForMapPoint(terminalPoint)
//	    let handler = NSDecimalNumberHandler(roundingMode: .plain,
//	                                         scale: 5,
//	                                         raiseOnExactness: false,
//	                                         raiseOnOverflow: false,
//	                                         raiseOnUnderflow: false,
//	                                         raiseOnDivideByZero: true)
//	    let latitude = NSDecimalNumber(value: terminal.latitude)
//	    let roundedLatitude = latitude.rounding(accordingToBehavior: handler)
//	    let longitude = NSDecimalNumber(value: terminal.longitude)
//	    let roundedLongitude = longitude.rounding(accordingToBehavior: handler)
//
//	    XCTAssertEqual(roundedLatitude.doubleValue, 61 - image.deltas.latitude)
//	    XCTAssertEqual(roundedLongitude.doubleValue, 100 + image.deltas.longitude)
    }
}
