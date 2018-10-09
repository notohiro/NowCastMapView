//
//  TileModel+Request.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/11.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public extension TileModel {
    /**
    A `Request` structure represents the coordinate deltas from edge to edge of `Tile` for specified `ZoomLevel`.
    */
    struct Request {

	    public let range: CountableClosedRange<Int>

	    public let scale: MKZoomScale

	    public let coordinates: Coordinates

	    public let mapRect: MKMapRect

	    public let withoutProcessing: Bool

	    public init(range: CountableClosedRange<Int>, scale: MKZoomScale, coordinates: Coordinates, withoutProcessing: Bool = false) {
    	    self.range = range
    	    self.scale = scale
    	    self.coordinates = coordinates
    	    self.mapRect = MKMapRect(coordinates: coordinates)
    	    self.withoutProcessing = withoutProcessing
	    }

	    public init(range: CountableClosedRange<Int>, scale: MKZoomScale, mapRect: MKMapRect, withoutProcessing: Bool = false) {
    	    self.range = range
    	    self.scale = scale
    	    self.coordinates = Coordinates(mapRect: mapRect)
    	    self.mapRect = mapRect
    	    self.withoutProcessing = withoutProcessing
	    }
    }
}
