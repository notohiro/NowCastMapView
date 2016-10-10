//
//  RainLevelsTest.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/7/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

@testable import NowCastMapView

class RainLevelsTest: BaseTestCase {

	func testInit() {
		let testPoints: [(point: CGPoint, expectedLevel: Int)] = [
			(CGPoint.init(x: 0, y: 2), 0),
			(CGPoint.init(x: 0, y: 0), 1),
			(CGPoint.init(x: 8, y: 15), 2),
			(CGPoint.init(x: 89, y: 104), 3),
			(CGPoint.init(x: 86, y: 106), 4),
			(CGPoint.init(x: 86, y: 111), 5),
			(CGPoint.init(x: 89, y: 114), 6),
			(CGPoint.init(x: 90, y: 114), 7),
			(CGPoint.init(x: 87, y: 116), 8)]

		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let image = image(file: "tile") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: image, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		for point in testPoints {
			guard let coordinate = tile.coordinate(at: point.point) else { XCTFail(); return }
			let tiles = [0 : tile]
			guard let rainLevels = RainLevels(baseTime: baseTime, coordinate: coordinate, tiles: tiles) else { XCTFail(); return }

			XCTAssertEqual(rainLevels.levels[0]?.rawValue, point.expectedLevel)
		}
	}

	func testInit0000() {
		let testPoints: [(point: CGPoint, expectedLevel: Int)] = [
			(CGPoint.init(x: 0, y: 0), 0)]

		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let image = image(file: "tile2") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: image, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		for point in testPoints {
			guard let coordinate = tile.coordinate(at: point.point) else { XCTFail(); return }
			let tiles = [0 : tile]
			guard let rainLevels = RainLevels(baseTime: baseTime, coordinate: coordinate, tiles: tiles) else { XCTFail(); return }

			XCTAssertEqual(rainLevels.levels[0]?.rawValue, point.expectedLevel)
		}
	}

	func testInitWithCoordinate() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let image = image(file: "tile") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: image, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		let tiles = [0 : tile]

		XCTAssertNil(RainLevels(baseTime: baseTime, coordinate: CLLocationCoordinate2DMake(62, 99), tiles: tiles))
	}
}
