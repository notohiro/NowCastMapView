//
//  ZoomLevelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/23.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest

@testable import NowCastMapView

class ZoomLevelTests: XCTestCase {
	func test() {
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
}
