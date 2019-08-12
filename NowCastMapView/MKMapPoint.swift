//
//  MKMapPoint.swift
//  NowCastMapView iOS
//
//  Created by Hiroshi Noto on 2019/07/12.
//  Copyright © 2019 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

extension MKMapPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension MKMapPoint: Equatable {
    public static func == (lhs: MKMapPoint, rhs: MKMapPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    public static func != (lhs: MKMapPoint, rhs: MKMapPoint) -> Bool {
        return !(lhs == rhs)
    }
}
