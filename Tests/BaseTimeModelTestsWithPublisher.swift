//
//  BaseTimeModelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/19/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import XCTest
import Combine

@testable import NowCastMapView

//@available(iOS 13.0, *)
//class BaseTimeModelTestsWithPublisher: BaseTestCase {
//    var baseTimeModel = BaseTimeModel()
//
//    private var exp: XCTestExpectation?
//
//    override func setUp() {
//	    super.setUp()
//
//	    baseTimeModel = BaseTimeModel()
//
//        exp = nil
//    }
//
//    func testFetch() {
//        let exp = expectation(description: "")
//        exp.expectedFulfillmentCount = 1
//
//        let sub = baseTimeModel.$current
//            .filter { $0 != nil }
//            .sink { _ in exp.fulfill() }
//
//        baseTimeModel.fetch()
//
//        wait(for: [exp], timeout: BaseTestCase.timeout)
//
//        sub.cancel()
//    }
//
//    func testConcurrentFetchRequests() {
//        let exp = expectation(description: "")
//        exp.expectedFulfillmentCount = 1
//
//        let sub = baseTimeModel.$current
//            .filter { $0 != nil }
//            .sink { _ in exp.fulfill() }
//
//        baseTimeModel.fetch()
//        baseTimeModel.fetch()
//
//        wait(for: [exp], timeout: BaseTestCase.timeout)
//
//        sub.cancel()
//    }
//
//    func testFetchInterval() {
//        let exp = expectation(description: "")
//        exp.expectedFulfillmentCount = 3
//
//        let sub = baseTimeModel.$current
//            .filter { $0 != nil }
//            .sink { _ in exp.fulfill() }
//
//        let interval: TimeInterval = 3
//        baseTimeModel.verbose = true
//        baseTimeModel.fetchInterval = interval
//
//        wait(for: [exp], timeout: interval * Double(exp.expectedFulfillmentCount) + interval / 2)
//
//        sub.cancel()
//    }
//}
