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

			if !isInServiceArea() { printError(); return nil }
		}

		init?(zoomLevel: ZoomLevel, coordinate: CLLocationCoordinate2D) {
			if !TileModel.isServiceAvailable(at: coordinate) { return nil }

			self.zoomLevel = zoomLevel
			let deltas = Tile.Deltas(zoomLevel: zoomLevel)

			// initialize mods
			let latDoubleNumber = (coordinate.latitude - Constants.originLatitude) / -deltas.latitude
			var latitude = Int(floor(latDoubleNumber))
			let lonDoubleNumber = (coordinate.longitude - Constants.originLongitude) / deltas.longitude
			var longitude = Int(floor(lonDoubleNumber))

			// for terminal edge
			// ex: 4_4 is invalid, convert to 3_3
			if latitude == zoomLevel.rawValue { latitude -= 1 }
			if longitude == zoomLevel.rawValue { longitude -= 1 }

			self.latitude = latitude
			self.longitude = longitude

			if !isInServiceArea() { printError(); return nil }
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

		private func printError() {
			var output: [String] = []
			output.append("[ERROR] Tile.Modifiers initialization failed")
			output.append("[zoomLevel]: \(zoomLevel), [latitude]: \(latitude), [longitude]: \(longitude)")
			print(output)
		}
	}
}
