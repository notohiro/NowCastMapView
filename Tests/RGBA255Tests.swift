//
//  RGBA255Tests.swift
//  NowCastMapView iOS Tests
//
//  Created by Hiroshi Noto on 2019/07/10.
//  Copyright © 2019 Hiroshi Noto. All rights reserved.
//

import XCTest

import NowCastMapView

class RGBA255Tests: XCTestCase {
    func test() {
        let color1 = RGBA255(red: 1, green: 2, blue: 3, alpha: 4)
        let color2 = RGBA255(red: 1, green: 2, blue: 3, alpha: 4)
        let color3 = RGBA255(red: 2, green: 2, blue: 3, alpha: 4)

        XCTAssertEqual(color1, color2)
        XCTAssertNotEqual(color1, color3)
    }
}
