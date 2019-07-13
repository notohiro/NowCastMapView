//
//  CLLocationCoordinate2D.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/24.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
	    return lhs.hashValue == rhs.hashValue
    }
}
