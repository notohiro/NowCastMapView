//
//  RainLevelsModelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/10.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import CoreLocation

class RainLevelsModelTests: BaseTestCase, BaseTimeModelDelegate, RainLevelsModelDelegate {
	var baseTime: BaseTime?
	var result: RainLevelsModel.Result?
	var handlerExecuted = false

	override func setUp() {
		baseTime = nil
		result = nil
		handlerExecuted = false
	}

	func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
		self.baseTime = baseTime
	}

	func rainLevelsModel(_ model: RainLevelsModel, result: RainLevelsModel.Result) {
		self.result = result
	}

	func testRainLevelsWithRequest() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let rainLevelsModel = RainLevelsModel(baseTime: baseTime)
		rainLevelsModel.delegate = self

		let coordinate = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)

		let request = RainLevelsModel.Request(coordinate: coordinate, range: 0...0)
		XCTAssertNil(rainLevelsModel.rainLevels(with: request) {_ in self.handlerExecuted = true })

		wait(seconds: 3)

		switch result {
		case .succeeded(_, _)?:
			break
		default:
			XCTFail()
		}

		XCTAssertTrue(handlerExecuted)
	}

	func testRainLevelsWithInvalidRequest() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let rainLevelsModel = RainLevelsModel(baseTime: baseTime)
		rainLevelsModel.delegate = self

		let coordinate = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)

		let request = RainLevelsModel.Request(coordinate: coordinate, range: -100...0)
		XCTAssertNil(rainLevelsModel.rainLevels(with: request) {_ in self.handlerExecuted = true })

		wait(seconds: 3)

		switch result {
		case .failed(_)?:
			break
		default:
			XCTFail()
		}

		XCTAssertTrue(handlerExecuted)
	}
}
