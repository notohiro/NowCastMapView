//
//  URLTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/23.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest

@testable import NowCastMapView

class URLTests: BaseTestCase {
	func testURL() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }

		let urlAtIndex0 = URL(baseTime: baseTime, index: 0, modifiers: modifiers)
		XCTAssertEqual(urlAtIndex0?.absoluteString,
		               "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200225/201509200225/zoom6/0_0.png")

		let urlAtPast = URL(baseTime: baseTime, index: -1, modifiers: modifiers)
		XCTAssertEqual(urlAtPast?.absoluteString,
		               "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200220/201509200220/zoom6/0_0.png")

		let urlAtFuture = URL(baseTime: baseTime, index: 1, modifiers: modifiers)
		XCTAssertEqual(urlAtFuture?.absoluteString,
		               "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201509200225/201509200230/zoom6/0_0.png")
	}
}
