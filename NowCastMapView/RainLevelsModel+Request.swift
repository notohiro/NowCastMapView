//
//  RainLevelsModel+Request.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/03.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import CoreLocation

extension RainLevelsModel {
	public struct Request {
		public let coordinate: CLLocationCoordinate2D
		public let range: CountableClosedRange<Int>

		public init(coordinate: CLLocationCoordinate2D, range: CountableClosedRange<Int>) {
			self.coordinate = coordinate
			self.range = range
		}
	}
}

// MARK: - Hashable

extension RainLevelsModel.Request: Hashable {
	public var hashValue: Int {
		return ("\(coordinate.latitude)" + "\(coordinate.longitude)" + "\(range)").hashValue
	}
}

// MARK: - Equatable

extension RainLevelsModel.Request: Equatable {
	public static func == (lhs: RainLevelsModel.Request, rhs: RainLevelsModel.Request) -> Bool {
		return lhs.coordinate == rhs.coordinate && lhs.range == rhs.range
	}
}
