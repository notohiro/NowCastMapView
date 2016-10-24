//
//  Tile+Deltas.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 8/16/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

extension Tile {
	/**
	A `Deltas` structure represents the coordinate deltas from edge to edge of `Tile` for specified `ZoomLevel`.
	*/
	public struct Deltas {
		let latitude: Double
		let longitude: Double

		init(zoomLevel: ZoomLevel) {
			latitude = Double(Constants.originLatitude - Constants.terminalLatitude) / Double(zoomLevel.rawValue)
			longitude = Double(Constants.terminalLongitude - Constants.originLongitude) / Double(zoomLevel.rawValue)
		}
	}
}
