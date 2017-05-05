//
//  Tile+Modifiers.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/2/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import CoreLocation

extension Tile {
	/**
	A `Modifiers` structure contains modifiers part of `Tile.url`.
	`zoomLevel`/`longitude`_`latitude`.png
	http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/201610101145/201610101145/zoom2/0_0.png
	*/
	public struct Modifiers {
		public let zoomLevel: ZoomLevel

		public let latitude: Int
		public let longitude: Int

		// MARK: - Functions

		init?(zoomLevel: ZoomLevel, latitude: Int, longitude: Int) {
			self.zoomLevel = zoomLevel
			self.latitude = latitude
			self.longitude = longitude

			if !isInServiceArea() { return nil }
		}

		init?(zoomLevel: ZoomLevel, coordinate: CLLocationCoordinate2D) {
			if !TileModel.isServiceAvailable(at: coordinate) { return nil }

			self.zoomLevel = zoomLevel
			let deltas = Tile.Deltas(zoomLevel: zoomLevel)

			let latDoubleNumber = (coordinate.latitude - Constants.originLatitude) / -deltas.latitude
			var latitude = Int(floor(latDoubleNumber))
			let lonDoubleNumber = (coordinate.longitude - Constants.originLongitude) / deltas.longitude
			var longitude = Int(floor(lonDoubleNumber))

			// If the coordinate points the bound of service area, modifiers could specify out of service area,
			// because right and bottom edge of a `Tile` are contained by next tiles.
			// And, it's guaranteed that coordinate is within service area
			// hence a `TileModel.isServiceAvailable` function is called at the top of initializer.
			// Therefore, if the modifiers specify the out of service area, convert modifiers to bound of service area.
			if latitude == zoomLevel.rawValue { latitude -= 1 }
			if longitude == zoomLevel.rawValue { longitude -= 1 }

			self.latitude = latitude
			self.longitude = longitude

			if !isInServiceArea() {
				var message = "TileModel.isServiceAvailable == true, but initialization failed. "
				message += "zoomLevel: \(zoomLevel), coordinate: \(coordinate)"
				Logger.log(self, logLevel: .error, message: message)
				return nil
			}
		}

		public func isOnServiceBound() -> (east: Bool, south: Bool) {
			return (longitude == zoomLevel.rawValue - 1, latitude == zoomLevel.rawValue - 1)
		}

		// MARK: - Helper Functions

		private func isInServiceArea() -> Bool {
			// initialize mods
			if latitude < 0 { return false }
			if latitude > zoomLevel.rawValue - 1 { return false }

			if longitude < 0 { return false }
			if longitude > zoomLevel.rawValue - 1 { return false }

			return true
		}
	}
}
