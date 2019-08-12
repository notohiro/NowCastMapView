//
//  MKMapSize.swift
//  NowCastMapView iOS
//
//  Created by Hiroshi Noto on 2019/07/12.
//  Copyright © 2019 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

extension MKMapSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}

extension MKMapSize: Equatable {
    public static func == (lhs: MKMapSize, rhs: MKMapSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }

    public static func != (lhs: MKMapSize, rhs: MKMapSize) -> Bool {
        return !(lhs == rhs)
    }
}
