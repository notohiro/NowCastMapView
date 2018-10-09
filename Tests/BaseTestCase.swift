//
//  BaseTestCase.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 5/14/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import XCTest

@testable import NowCastMapView

class BaseTestCase: XCTestCase {
    static let timeout = 3.0

    func baseTime(file fileName: String) -> BaseTime? {
	    let baseTime = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "xml").flatMap {
    	    (try? Data(contentsOf: URL(fileURLWithPath: $0))).flatMap { BaseTime(baseTimeData: $0) }
	    }

	    return baseTime
    }

    func image(file fileName: String) -> UIImage? {
	    return Bundle(for: type(of: self)).path(forResource: fileName, ofType: "png").flatMap {
    	    (try? Data(contentsOf: URL(fileURLWithPath: $0))).flatMap { UIImage(data: $0) }
	    }
    }

    func wait(seconds: TimeInterval) {
	    RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
    }
}
