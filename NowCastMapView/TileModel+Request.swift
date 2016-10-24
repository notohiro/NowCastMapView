//
//  TileModel+Request.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/11.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

extension TileModel {
	/**
	A `Request` structure represents the coordinate deltas from edge to edge of `Tile` for specified `ZoomLevel`.
	*/
	public struct Request {

		public let index: Int

		public let scale: MKZoomScale

		public let coordinates: Coordinates

		public init(index: Int, scale: MKZoomScale, coordinates: Coordinates) {
			self.index = index
			self.scale = scale
			self.coordinates = coordinates
		}
	}
}
