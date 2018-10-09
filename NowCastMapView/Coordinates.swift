//
//  Coordinates.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/1/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

/**
A `Coordinates` structure contains two `CLLocationCoordinate2D` objects to represent rectangle on the map.
The `Coordinates` could be converted from a `MKMapRect` by using initializer.
*/
public struct Coordinates {

    /// The coordinate of top left.
    public var origin: CLLocationCoordinate2D

    /// The coordinate of bottom right.
    public var terminal: CLLocationCoordinate2D

    public init(origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) {
	    self.origin = origin
	    self.terminal = terminal
    }

    public init(modifiers: Tile.Modifiers) {
	    let deltas = Tile.Deltas(zoomLevel: modifiers.zoomLevel)
	    let originLatitude = Constants.originLatitude - Double(modifiers.latitude) * deltas.latitude
	    let originLongitude = Constants.originLongitude + Double(modifiers.longitude) * deltas.longitude
	    let terminalLatitude = originLatitude - deltas.latitude
	    let terminalLongitude = originLongitude + deltas.longitude

	    origin = CLLocationCoordinate2DMake(originLatitude, originLongitude)
	    terminal = CLLocationCoordinate2DMake(terminalLatitude, terminalLongitude)
    }

    public init(mapRect: MKMapRect) {
	    // mapRect origin Coordinate
	    origin = mapRect.origin.coordinate

	    // mapRect terminal Coordinate
	    let terminalPoint = MKMapPoint(x: mapRect.origin.x + mapRect.size.width, y: mapRect.origin.y + mapRect.size.height)
	    terminal = terminalPoint.coordinate
    }

    public func intersecting(_ coordinates: Coordinates) -> Coordinates? {
	    let newOrigin = CLLocationCoordinate2DMake(min(origin.latitude, coordinates.origin.latitude),
	                                               max(origin.longitude, coordinates.origin.longitude))
	    let newTerminal = CLLocationCoordinate2DMake(max(terminal.latitude, coordinates.terminal.latitude),
	                                                 min(terminal.longitude, coordinates.terminal.longitude))

	    if newOrigin.latitude < newTerminal.latitude || newOrigin.longitude > newTerminal.longitude { return nil }

	    return Coordinates(origin: newOrigin, terminal: newTerminal)
    }
}
