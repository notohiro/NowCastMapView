//
//  CLLocationCoordinate2D.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/24.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D: Equatable {
	public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		return (lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
	}
}
