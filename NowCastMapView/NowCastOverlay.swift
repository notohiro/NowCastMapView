//
//  NowCastOverlay.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

internal class NowCastOverlay: NSObject, MKOverlay {
	override internal init() { }

	internal var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2DMake((kNowCastOriginLatitude + kNowCastTerminalLatitude)/2, (kNowCastOriginLongitude + kNowCastTerminalLongitude)/2)
	}

	internal var boundingMapRect: MKMapRect {
		let origin = MKMapPointForCoordinate(CLLocationCoordinate2DMake(kNowCastOriginLatitude, kNowCastOriginLongitude))
		let end = MKMapPointForCoordinate(CLLocationCoordinate2DMake(kNowCastTerminalLatitude, kNowCastTerminalLongitude))
		let size = MKMapSizeMake(end.x - origin.x, end.y - origin.y)

		return MKMapRectMake(origin.x, origin.y, size.width, size.height);
	}
}
