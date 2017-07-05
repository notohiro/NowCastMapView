//
//  TileModelTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/23.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

@testable import NowCastMapView

class TileModelTests: BaseTestCase, BaseTimeModelDelegate, TileModelDelegate {
	var baseTime: BaseTime?
	var addedCount = 0
	var failedCount = 0
	var handlerExecuted = false

	override func setUp() {
		super.setUp()

		baseTime = nil
		addedCount = 0
		failedCount = 0
		handlerExecuted = false
	}

	func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
		self.baseTime = baseTime
	}

	func tileModel(_ model: TileModel, task: TileModel.Task, added tile: Tile) {
		objc_sync_enter(self)
		addedCount += 1
		objc_sync_exit(self)
	}

	func tileModel(_ model: TileModel, task: TileModel.Task, failed url: URL, error: Error) {
		print(error)

		objc_sync_enter(self)
		failedCount += 1
		objc_sync_exit(self)
	}

	func testTilesWithRequest() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let tileModel = TileModel(baseTime: baseTime, delegate: self)

		let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
		let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(range: 0...0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)

		do {
			let task1 = try tileModel.tiles(with: request) { _ in self.handlerExecuted = true }
			let task2 = try tileModel.tiles(with: request, completionHandler: nil)
			task1.resume()
			task2.resume()

			wait(seconds: 3)
			XCTAssertEqual(addedCount, 16*2)
			XCTAssertEqual(failedCount, 0)
			XCTAssertEqual(task1.completedTiles.count, 16)
			XCTAssertEqual(task2.completedTiles.count, 16)
			XCTAssertEqual(task1.state, .completed)
			XCTAssertEqual(task2.state, .completed)
			XCTAssertTrue(handlerExecuted)
		} catch {
			XCTFail()
		}
	}

	func testTilesWithRequestWithoutProcessing() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let tileModel = TileModel(baseTime: baseTime, delegate: self)

		let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
		let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(range: 0...0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates, withoutProcessing: true)

		do {
			let task1 = try tileModel.tiles(with: request) { _ in self.handlerExecuted = true }
			let task2 = try tileModel.tiles(with: request, completionHandler: nil)
			task1.resume()
			task2.resume()
		} catch {
			XCTFail()
		}

		wait(seconds: 3)
		XCTAssertEqual(addedCount, 16)
		XCTAssertEqual(failedCount, 0)
		XCTAssertTrue(handlerExecuted)
	}

	func testTilesWithIntersectMapRectRequest() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let tileModel = TileModel(baseTime: baseTime, delegate: self)

		let origin = CLLocationCoordinate2DMake(Constants.originLatitude + 1, Constants.originLongitude)
		let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(range: 0...0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)

		do {
			let task = try tileModel.tiles(with: request) { _ in self.handlerExecuted = true }
			task.resume()
		} catch {
			XCTFail()
		}

		wait(seconds: 3)
		XCTAssertNotEqual(addedCount, 0)
		XCTAssertEqual(failedCount, 0)
		XCTAssertTrue(handlerExecuted)
	}

	func testTilesWithIntersectInvalidMapRectRequest() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let tileModel = TileModel(baseTime: baseTime, delegate: self)

		let origin = CLLocationCoordinate2DMake(1, 0)
		let terminal = CLLocationCoordinate2DMake(0, 1)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(range: 0...0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)

		do {
			let task = try tileModel.tiles(with: request) { _ in self.handlerExecuted = true }
			task.resume()
			XCTFail()
		} catch NCError.outOfService {
			// OK
		} catch {
			XCTFail()
		}

		wait(seconds: 3)
		XCTAssertEqual(addedCount, 0)
		XCTAssertEqual(failedCount, 0)
		XCTAssertFalse(handlerExecuted)
	}

	func testTaskCancel() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let tileModel = TileModel(baseTime: baseTime, delegate: self)

		let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
		let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(range: 0...0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)

		do {
			let task = try tileModel.tiles(with: request) { _ in self.handlerExecuted = true }
			task.resume()
			task.invalidateAndCancel()
		} catch {
			XCTFail()
		}

		wait(seconds: 3)
		XCTAssertEqual(addedCount, 0)
		XCTAssertEqual(failedCount, 0)
		XCTAssertFalse(handlerExecuted)
	}

	func testModelCancel() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let tileModel = TileModel(baseTime: baseTime, delegate: self)

		let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
		let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(range: 0...0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)

		do {
			let task = try tileModel.tiles(with: request) { _ in self.handlerExecuted = true }
			task.resume()
		} catch {
			XCTFail()
		}

		tileModel.cancelAll()

		wait(seconds: 3)
		XCTAssertEqual(addedCount, 0)
		XCTAssertEqual(failedCount, 0)
		XCTAssertFalse(handlerExecuted)
	}

	func testIsServiceAvailableWithinMapRect() {
		let originCoordinateOutOfService = CLLocationCoordinate2DMake(5, 150)
		let terminalCoordinateOutOfService = CLLocationCoordinate2DMake(2, 152)
		let coordinatesOutOfService = Coordinates(origin: originCoordinateOutOfService, terminal: terminalCoordinateOutOfService)
		XCTAssertFalse(TileModel.isServiceAvailable(within: coordinatesOutOfService))

		let originCoordinateOverlapped = CLLocationCoordinate2DMake(60, 90)
		let terminalCoordinateOverlapped = CLLocationCoordinate2DMake(5, 110)
		let coordinatesOverlapped = Coordinates(origin: originCoordinateOverlapped, terminal: terminalCoordinateOverlapped)
		XCTAssertTrue(TileModel.isServiceAvailable(within: coordinatesOverlapped))

		let originCoordinateInside = CLLocationCoordinate2DMake(60, 110)
		let terminalcoordinateInside = CLLocationCoordinate2DMake(59, 120)
		let coordinatesInsideService = Coordinates(origin: originCoordinateInside, terminal: terminalcoordinateInside)
		XCTAssertTrue(TileModel.isServiceAvailable(within: coordinatesInsideService))
	}

	func testIsServiceAvailableAtCoordinate() {
		let coordinateInsideService = CLLocationCoordinate2DMake(60, 101)
		XCTAssertTrue(TileModel.isServiceAvailable(at: coordinateInsideService))

		let coordinateOutsideService = CLLocationCoordinate2DMake(62, 99)
		XCTAssertFalse(TileModel.isServiceAvailable(at: coordinateOutsideService))
	}
}
