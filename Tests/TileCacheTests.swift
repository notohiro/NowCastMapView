//
//  TileCacheTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/05/07.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import MapKit
import XCTest

@testable import NowCastMapView

class TileCacheTests: BaseTestCase, BaseTimeModelDelegate, TileModelDelegate {
    var baseTime: BaseTime?
    var addedCount = 0
    var failedCount = 0

    override func setUp() {
	    super.setUp()

	    baseTime = nil
	    addedCount = 0
	    failedCount = 0
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

	    let tileCache = TileCache(baseTime: baseTime, delegate: self)

	    let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
	    let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
	    let coordinates = Coordinates(origin: origin, terminal: terminal)

	    let request = TileModel.Request(range: 0...0, scale: ZoomLevel.MKZoomScaleForLevel2, coordinates: coordinates)

	    do {
    	    let tiles = try tileCache.tiles(with: request)

    	    XCTAssertEqual(tiles.count, 0)
	    } catch {
    	    XCTFail()
	    }

	    wait(seconds: 3)
	    XCTAssertEqual(addedCount, 16)
	    XCTAssertEqual(failedCount, 0)

	    do {
    	    let cachedTiles = try tileCache.tiles(with: request)

    	    XCTAssertEqual(cachedTiles.count, 16)
	    } catch {
    	    XCTFail()
	    }
    }
}
