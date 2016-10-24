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
	var rainLevels: RainLevels?

	override func setUp() {
		baseTime = nil
		rainLevels = nil
	}

	func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
		self.baseTime = baseTime
	}

	func rainLevelsModel(_ model: RainLevelsModel, added rainLevels: RainLevels) {
		self.rainLevels = rainLevels
	}

	func rainLevelsModel(_ model: RainLevelsModel, failed request: RainLevelsModel.Request) {
		self.rainLevels = nil
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
		XCTAssertNil(rainLevelsModel.rainLevels(with: request))

		wait(seconds: 3)

		XCTAssertNotNil(self.rainLevels)
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
		XCTAssertNil(rainLevelsModel.rainLevels(with: request))

		wait(seconds: 3)

		XCTAssertNil(self.rainLevels)
	}
}
