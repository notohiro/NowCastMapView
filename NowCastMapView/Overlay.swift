//
//  Overlay.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public class Overlay: NSObject, MKOverlay {
    public var coordinate: CLLocationCoordinate2D {
	    let latitude = (Constants.originLatitude + Constants.terminalLatitude) / 2
	    let longitude = (Constants.originLongitude + Constants.terminalLongitude) / 2
	    return CLLocationCoordinate2DMake(latitude, longitude)
    }

    public var boundingMapRect: MKMapRect {
	    let origin = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude))
	    let end = MKMapPointForCoordinate(CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude))
	    let size = MKMapSizeMake(end.x - origin.x, end.y - origin.y)

	    return MKMapRectMake(origin.x, origin.y, size.width, size.height)
    }

    public func intersects(_ mapRect: MKMapRect) -> Bool {
	    return MKMapRectIntersectsRect(mapRect, TileModel.serviceAreaMapRect)
    }
}
