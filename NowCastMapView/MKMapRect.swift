//
//  MKMapRect.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 8/16/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

/// The extension of `MKMapRect` to provide initializer with `Tile.Modifiers`.
public extension MKMapRect {
    /// Creates a new `MKMapRect` structure from the specified values.
    init(modifiers: Tile.Modifiers) {
	    let deltas = Tile.Deltas(zoomLevel: modifiers.zoomLevel)

	    let coordinates = Coordinates(modifiers: modifiers)

	    let originLatitude = coordinates.origin.latitude
	    let originLongitude = coordinates.origin.longitude

	    let origin = MKMapPoint(CLLocationCoordinate2DMake(originLatitude, originLongitude))
        let terminal = MKMapPoint(CLLocationCoordinate2DMake(originLatitude - deltas.latitude,
                                                             originLongitude + deltas.longitude))
	    let size = MKMapSize(width: terminal.x - origin.x, height: terminal.y - origin.y)

	    self.init(origin: origin, size: size)
    }

    /// Creates a new `MKMapRect` structure from the specified values.
    init(coordinates: Coordinates) {
	    let origin = MKMapPoint(coordinates.origin)
	    let terminal = MKMapPoint(coordinates.terminal)
	    let size = MKMapSize(width: terminal.x - origin.x, height: terminal.y - origin.y)

	    self.init(origin: origin, size: size)
    }
}

extension MKMapRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin)
        hasher.combine(size)
    }
}

extension MKMapRect: Equatable {
    public static func == (lhs: MKMapRect, rhs: MKMapRect) -> Bool {
        return lhs.origin == rhs.origin && lhs.size == rhs.size
    }

    public static func != (lhs: MKMapRect, rhs: MKMapRect) -> Bool {
        return !(lhs == rhs)
    }
}
