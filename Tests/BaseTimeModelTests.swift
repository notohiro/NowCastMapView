//
//  BaseTimeModelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/19/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest

@testable import NowCastMapView

class BaseTimeModelTests: BaseTestCase, BaseTimeModelDelegate {
    var baseTimeModel = BaseTimeModel()

    private var exp: XCTestExpectation?

    override func setUp() {
	    super.setUp()

	    baseTimeModel = BaseTimeModel()
	    baseTimeModel.delegate = self
    }

    override func tearDown() {
         exp = nil
    }

    func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
	    if baseTime != nil {
    	    exp?.fulfill()
	    }
    }

    func testFetch() {
        let exp = expectation(description: "")
        self.exp = exp
        exp.expectedFulfillmentCount = 1

	    baseTimeModel.fetch()

        wait(for: [exp], timeout: BaseTestCase.timeout)
    }

    func testConcurrentFetchRequests() {
        let exp = expectation(description: "")
        self.exp = exp
        exp.expectedFulfillmentCount = 1

	    baseTimeModel.fetch()
	    baseTimeModel.fetch()

        wait(for: [exp], timeout: BaseTestCase.timeout)
    }

    func testFetchInterval() {
        let exp = expectation(description: "")
        self.exp = exp
        exp.expectedFulfillmentCount = 3

	    let interval: TimeInterval = 3
	    baseTimeModel.fetchInterval = interval
        baseTimeModel.verbose = true

        wait(for: [exp], timeout: interval * Double(exp.expectedFulfillmentCount) + interval / 2)
    }
}
