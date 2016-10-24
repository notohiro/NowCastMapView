//
//  TileTests.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/10/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import XCTest
import MapKit

@testable import NowCastMapView

class TileModfiersTest: BaseTestCase {
	func testInit() {
		let coordinateAtRtightBottomOf00 = CLLocationCoordinate2DMake(47.6, 117.4)
		guard let modifiers00 = Tile.Modifiers(zoomLevel: .level2, coordinate: coordinateAtRtightBottomOf00) else { XCTFail(); return }
		XCTAssertEqual(modifiers00.latitude, 0)
		XCTAssertEqual(modifiers00.longitude, 0)

		let coordinateAtRtightBottomOf11 = CLLocationCoordinate2DMake(47.5, 117.5)
		guard let modifiers11 = Tile.Modifiers(zoomLevel: .level2, coordinate: coordinateAtRtightBottomOf11) else { XCTFail(); return }
		XCTAssertEqual(modifiers11.latitude, 1)
		XCTAssertEqual(modifiers11.longitude, 1)
	}
}



class TileTests: BaseTestCase {
	func testContains() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: nil, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		let coordinates = tile.coordinates
		XCTAssertTrue(tile.contains(coordinates.origin))
		XCTAssertFalse(tile.contains(CLLocationCoordinate2DMake(coordinates.origin.latitude, coordinates.terminal.longitude)))
		XCTAssertFalse(tile.contains(CLLocationCoordinate2DMake(coordinates.terminal.latitude, coordinates.origin.longitude)))
		XCTAssertFalse(tile.contains(coordinates.terminal))
	}

	func testColorAtCoordinate() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let image = image(file: "tile") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: image, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		guard let rgba255 = tile.rgba255(at: tile.coordinates.origin) else { XCTFail(); return }

		let color = UIColor(rgba255: rgba255)

		XCTAssertEqual(color, RainLevel.rainLevelToColor[1])

		XCTAssertNil(tile.rgba255(at: tile.coordinates.terminal))
	}

	func testPointAtCoordinate() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let image = image(file: "tile") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: image, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		guard let originPoint = tile.point(at: tile.coordinates.origin) else { XCTFail(); return }
		XCTAssertEqual(originPoint, CGPoint.init(x: 0, y: 0))

		XCTAssertNil(tile.point(at: tile.coordinates.terminal))

		let middleLatitude = tile.coordinates.origin.latitude - (tile.deltas.latitude / 2)
		let middleLongitude = tile.coordinates.origin.longitude + (tile.deltas.longitude / 2)
		guard let middlePoint = tile.point(at: CLLocationCoordinate2DMake(middleLatitude, middleLongitude)) else { XCTFail(); return }
		guard let imageData = tile.image else { XCTFail(); return }

		XCTAssertEqual(middlePoint, CGPoint.init(x: (imageData.size.width)/2, y: (imageData.size.height)/2))
	}

	func testPositionAtCoordinate() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let image = image(file: "tile") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: image, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		guard let originPosition = tile.position(at: tile.coordinates.origin) else { XCTFail(); return }

		XCTAssertEqual(originPosition.latitudePosition, 0.0)
		XCTAssertEqual(originPosition.longitudePosition, 0.0)

		XCTAssertNil(tile.position(at: tile.coordinates.terminal))

		let middleLatitude = tile.coordinates.origin.latitude - (tile.deltas.latitude / 2)
		let middleLongitude = tile.coordinates.origin.longitude + (tile.deltas.longitude / 2)
		let middleCoordinate = CLLocationCoordinate2DMake(middleLatitude, middleLongitude)
		guard let middlePotision = tile.position(at: middleCoordinate) else { XCTFail(); return }

		XCTAssertEqual(middlePotision.latitudePosition, 0.5)
		XCTAssertEqual(middlePotision.longitudePosition, 0.5)
	}

	// return coordinate for center of pixel
	func testCoordinateAtPoint() {
		guard let baseTime = baseTime(file: "OldBaseTime") else { XCTFail(); return }
		guard let image = image(file: "tile") else { XCTFail(); return }

		guard let modifiers = Tile.Modifiers(zoomLevel: .level6, latitude: 0, longitude: 0) else { XCTFail(); return }
		guard let url = URL(baseTime: baseTime, index: 0, modifiers: modifiers) else { XCTFail(); return }
		let tile = Tile(image: image, baseTime: baseTime, index: 0, modifiers: modifiers, url: url)

		guard let originCoordinate = tile.coordinate(at: CGPoint.init(x: 0, y: 0)) else { XCTFail(); return }
		guard let originPoint = tile.point(at: originCoordinate) else { XCTFail(); return }
		XCTAssertEqual(originPoint, CGPoint.init(x: 0, y: 0))

		guard let terminalCoordinate = tile.coordinate(at: CGPoint.init(x: image.size.width - 1, y: image.size.height - 1)) else {
			XCTFail()
			return
		}
		guard let terminalPoint = tile.point(at: terminalCoordinate) else { XCTFail(); return }

		XCTAssertEqual(terminalPoint, CGPoint.init(x: image.size.width - 1, y: image.size.height - 1))
		XCTAssertNil(tile.coordinate(at: CGPoint.init(x: -1, y: -1)))
		XCTAssertNil(tile.coordinate(at: CGPoint.init(x: image.size.width, y: image.size.height)))
	}
}
