//
//  RainLevelsModelRequestTests.swift
//  NowCastMapView iOS Tests
//
//  Created by Hiroshi Noto on 2019/07/11.
//  Copyright © 2019 Hiroshi Noto. All rights reserved.
//

import XCTest
import CoreLocation

import NowCastMapView

class RainLevelsModelRequestTests: XCTestCase {
    func testHashable() {
        let coordianate1 = CLLocationCoordinate2DMake(0, 0)
        let coordianate2 = CLLocationCoordinate2DMake(0, 1)
        let req1 = RainLevelsModel.Request(coordinate: coordianate1, range: 0...1)
        let req2 = RainLevelsModel.Request(coordinate: coordianate1, range: 0...1)
        let req3 = RainLevelsModel.Request(coordinate: coordianate2, range: 0...1)
        let req4 = RainLevelsModel.Request(coordinate: coordianate1, range: 0...2)

        XCTAssertEqual(req1, req2)
        XCTAssertNotEqual(req1, req3)
        XCTAssertNotEqual(req1, req4)
    }
}
