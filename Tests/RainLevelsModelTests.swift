//
//  RainLevelsModelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/10.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import CoreLocation
import XCTest

@testable import NowCastMapView

class RainLevelsModelTests: BaseTestCase, BaseTimeModelDelegate, RainLevelsModelDelegate {
    var baseTime: BaseTime?
    var result: RainLevelsModel.Result?
    var handlerExecuted = false

    override func setUp() {
	    super.setUp()

	    baseTime = nil
	    result = nil
	    handlerExecuted = false
    }

    func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
	    self.baseTime = baseTime
    }

    func rainLevelsModel(_ model: RainLevelsModel, task: RainLevelsModel.Task, result: RainLevelsModel.Result) {
	    self.result = result
    }

    func testRainLevelsWithRequest() {
	    let baseTimeModel = BaseTimeModel()
	    baseTimeModel.delegate = self
	    baseTimeModel.fetch()
	    wait(seconds: BaseTestCase.timeout)
	    XCTAssertNotNil(baseTime)

	    guard let baseTime = self.baseTime else { XCTFail(); return }

	    let rainLevelsModel = RainLevelsModel(baseTime: baseTime, delegate: self)

	    let coordinate = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
	    let request = RainLevelsModel.Request(coordinate: coordinate, range: -12...12)

	    do {
    	    let task = try rainLevelsModel.rainLevels(with: request) { _ in self.handlerExecuted = true }
    	    task.resume()

    	    wait(seconds: 3)

    	    switch result {
    	    case let .succeeded(_, rainLevels)?:
	    	    print(rainLevels)
    	    default:
	    	    XCTFail()
    	    }

    	    XCTAssertTrue(handlerExecuted)
    	    XCTAssert(rainLevelsModel.tasks.isEmpty)
	    } catch {
    	    XCTFail()
	    }
    }

// fix later
//    func testRainLevelsWithInvalidRange() {
//	    let baseTimeModel = BaseTimeModel()
//	    baseTimeModel.delegate = self
//	    baseTimeModel.fetch()
//	    wait(seconds: BaseTestCase.timeout)
//	    XCTAssertNotNil(baseTime)
//
//	    guard let baseTime = self.baseTime else { XCTFail(); return }
//
//	    let rainLevelsModel = RainLevelsModel(baseTime: baseTime, delegate: self)
//
//	    let coordinate = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
//
//	    let request = RainLevelsModel.Request(coordinate: coordinate, range: -100...0)
//
//	    do {
//    	    _ = try rainLevelsModel.rainLevels(with: request) { _ in self.handlerExecuted = true }
//    	    XCTFail()
//	    } catch {
//    	    // OK
//	    }
//
//	    wait(seconds: 3)
//
//	    XCTAssertNil(result)
//
//	    XCTAssertFalse(handlerExecuted)
//	    XCTAssert(rainLevelsModel.tasks.count == 0)
//    }

    func testRainLevelsWithInvalidCoordinate() {
	    let baseTimeModel = BaseTimeModel()
	    baseTimeModel.delegate = self
	    baseTimeModel.fetch()
	    wait(seconds: BaseTestCase.timeout)
	    XCTAssertNotNil(baseTime)

	    guard let baseTime = self.baseTime else { XCTFail(); return }

	    let rainLevelsModel = RainLevelsModel(baseTime: baseTime, delegate: self)

	    let coordinate = CLLocationCoordinate2DMake(1, 1)

	    let request = RainLevelsModel.Request(coordinate: coordinate, range: 0...0)

	    do {
    	    _ = try rainLevelsModel.rainLevels(with: request) { _ in self.handlerExecuted = true }
    	    XCTFail()
	    } catch NCError.outOfService {
    	    // OK
	    } catch {
    	    XCTFail()
	    }

	    wait(seconds: 3)

	    XCTAssertNil(result)

	    XCTAssertFalse(handlerExecuted)
	    XCTAssert(rainLevelsModel.tasks.isEmpty)
    }

    func testRainLevelsCancel() {
	    let baseTimeModel = BaseTimeModel()
	    baseTimeModel.delegate = self
	    baseTimeModel.fetch()
	    wait(seconds: BaseTestCase.timeout)
	    XCTAssertNotNil(baseTime)

	    guard let baseTime = self.baseTime else { XCTFail(); return }

	    let rainLevelsModel = RainLevelsModel(baseTime: baseTime, delegate: self)

	    let coordinate = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)

	    let request = RainLevelsModel.Request(coordinate: coordinate, range: -12...12)

	    do {
    	    let task = try rainLevelsModel.rainLevels(with: request) { _ in self.handlerExecuted = true }
    	    task.resume()
    	    task.cancel()
	    } catch {
    	    XCTFail()
	    }

	    wait(seconds: 3)

	    XCTAssertNil(result)
	    XCTAssertFalse(handlerExecuted)
	    XCTAssertEqual(rainLevelsModel.tasks.count, 0)
    }
}
