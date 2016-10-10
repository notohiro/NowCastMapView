//
//  MKMapRect.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 8/16/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

extension MKMapRect {
	public init(modifiers: Tile.Modifiers) {
		let deltas = Tile.Deltas(zoomLevel: modifiers.zoomLevel)
		// make mapRect
		// top left coordinate of tile
		let coordinates = Coordinates(modifiers: modifiers)
		let originLatitude = coordinates.origin.latitude
		let originLongitude = coordinates.origin.longitude

		// MKMapPoint, MKMapSize of origin, terminal
		let origin = MKMapPointForCoordinate(CLLocationCoordinate2DMake(originLatitude, originLongitude))
		let terminal = MKMapPointForCoordinate(CLLocationCoordinate2DMake(originLatitude - deltas.latitude, originLongitude + deltas.longitude))
		let size = MKMapSizeMake(terminal.x - origin.x, terminal.y - origin.y)

		self.init(origin: origin, size: size)
	}
}
