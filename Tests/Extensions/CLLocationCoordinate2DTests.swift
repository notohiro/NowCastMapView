//
//  CLLocationCoordinate2DTests.swift
//  NowCastMapView iOS Tests
//
//  Created by Hiroshi Noto on 2019/07/12.
//  Copyright © 2019 Hiroshi Noto. All rights reserved.
//

import XCTest
import CoreLocation

class CLLocationCoordinate2DTests: XCTestCase {
    func test() {
        coordinate1 = CLLocationCoordinate2DMake(0, 0)
        coordinate2 = CLLocationCoordinate2DMake(0, 0)
        coordinate3 = CLLocationCoordinate2DMake(0, 1)

        XCTAssertEqual(coordinate1, coordinate2)
        XCTAssertNotEqual(coordinate1, coordinate3)
    }
}
