//
//  RainLevelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/07/13.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import XCTest

@testable import NowCastMapView

class RainLevelTests: XCTestCase {
    func test() {
        // swiftlint:disable colon
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 255, green: 255, blue: 255, alpha: 255))?.rawValue, 0)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 255, green: 255, blue: 255, alpha:   0))?.rawValue, 0)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red:   0, green:   0, blue:   0, alpha:   0))?.rawValue, 0)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 242, green: 242, blue: 255, alpha: 255))?.rawValue, 1)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 160, green: 210, blue: 255, alpha: 255))?.rawValue, 2)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red:  33, green: 140, blue: 255, alpha: 255))?.rawValue, 3)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red:   0, green:  65, blue: 255, alpha: 255))?.rawValue, 4)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 250, green: 245, blue:   0, alpha: 255))?.rawValue, 5)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 255, green: 153, blue:   0, alpha: 255))?.rawValue, 6)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 255, green:  40, blue:   0, alpha: 255))?.rawValue, 7)
	    XCTAssertEqual(RainLevel(rgba255: RGBA255(red: 180, green:   0, blue: 104, alpha: 255))?.rawValue, 8)
        // swiftlint:enable colon
    }
}
