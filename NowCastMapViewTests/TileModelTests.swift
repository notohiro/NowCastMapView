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

extension MKMapRect {
	static func makeMapRect(origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) -> MKMapRect {
		let originPoint = MKMapPointForCoordinate(origin)
		let terminalPoint = MKMapPointForCoordinate(terminal)
		let size = MKMapSizeMake(terminalPoint.x - originPoint.x, terminalPoint.y - originPoint.y)
		return MKMapRectMake(originPoint.x, originPoint.y, size.width, size.height)
	}
}

class TileModelTests: BaseTestCase, BaseTimeModelDelegate, TileModelDelegate {
	var baseTime: BaseTime?
	var addedCount = 0
	var failedCount = 0

	override func setUp() {
		baseTime = nil
		addedCount = 0
		failedCount = 0
	}

	func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
		self.baseTime = baseTime
	}

	func tileModel(_ model: TileModel, added tiles: Set<Tile>) {
		objc_sync_enter(self)
		addedCount += tiles.count
		objc_sync_exit(self)
	}

	func tileModel(_ model: TileModel, failed tile: Tile) {
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

		let tileModel = TileModel(baseTime: baseTime)
		tileModel.delegate = self

		let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
		let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(index: 0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)
		let tiles = tileModel.tiles(with: request)
		_ = tileModel.tiles(with: request)
		XCTAssertNotEqual(tiles.count, 0)
		tileModel.resume()

		wait(seconds: 3)
		XCTAssertEqual(addedCount, tiles.count)
		XCTAssertEqual(failedCount, 0)

		// tiles with cached
		let tilesWithCached = tileModel.tiles(with: request)
		XCTAssertEqual(tilesWithCached.filter { $0.image == nil }.count, 0)
		wait(seconds: 3)
		XCTAssertEqual(addedCount, tiles.count)
		XCTAssertEqual(failedCount, 0)
	}

	func testCancel() {
		let baseTimeModel = BaseTimeModel()
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		wait(seconds: BaseTestCase.timeout)
		XCTAssertNotNil(baseTime)

		guard let baseTime = self.baseTime else { XCTFail(); return }

		let tileModel = TileModel(baseTime: baseTime)
		tileModel.delegate = self

		let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
		let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
		let coordinates = Coordinates(origin: origin, terminal: terminal)

		let request = TileModel.Request(index: 0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)
		let tiles = tileModel.tiles(with: request)
		XCTAssertNotEqual(tiles.count, 0)

		tileModel.cancel()

		wait(seconds: 3)
		XCTAssertEqual(addedCount, 0)
		XCTAssertEqual(failedCount, tiles.count)
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
