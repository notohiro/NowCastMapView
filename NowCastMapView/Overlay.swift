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
	    let origin = MKMapPoint(CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude))
	    let end = MKMapPoint(CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude))
	    let size = MKMapSize(width: end.x - origin.x, height: end.y - origin.y)

	    return MKMapRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }

    deinit { }

    public func intersects(_ mapRect: MKMapRect) -> Bool {
	    return mapRect.intersects(TileModel.serviceAreaMapRect)
    }
}
