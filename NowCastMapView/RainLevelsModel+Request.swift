//
//  RainLevelsModel+Request.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/03.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import CoreLocation
import Foundation

public extension RainLevelsModel {
    struct Request: Hashable {
	    public let coordinate: CLLocationCoordinate2D
	    public let range: CountableClosedRange<Int>

	    public init(coordinate: CLLocationCoordinate2D, range: CountableClosedRange<Int>) {
    	    self.coordinate = coordinate
    	    self.range = range
	    }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
            hasher.combine(range)
        }
    }
}
