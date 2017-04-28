//
//  RainLevels.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/1/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import CoreLocation

public struct RainLevels {
	public let baseTime: BaseTime
	public let coordinate: CLLocationCoordinate2D
	public let tiles: [Int : Tile]
	public private(set) var levels = [Int: RainLevel]()

	// avoid call from main thread
	public init?(baseTime: BaseTime, coordinate: CLLocationCoordinate2D, tiles: [Int : Tile]) {
		self.baseTime = baseTime
		self.coordinate = coordinate
		self.tiles = tiles

		if !TileModel.isServiceAvailable(at: coordinate) { return nil }

		guard let levels = calculate() else { return nil }
		self.levels = levels
	}

	// this function run in not main queue when instance initialized
	private func calculate() -> [Int : RainLevel]? {
		var rainLevels = [Int: RainLevel]()
		var failed = false

		let queue = OperationQueue()
		tiles.forEach { (index, tile) in
			queue.addOperation {
				guard let rgba255 = tile.rgba255(at: self.coordinate) else { failed = true; return }
				guard let rainLevel = RainLevel(rgba255: rgba255) else { failed = true; return }

				rainLevels[index] = rainLevel
			}
		}
		queue.waitUntilAllOperationsAreFinished()

		return failed ? nil : rainLevels
	}
}

// MARK: - Hashable

//extension RainLevels: Hashable {
//	public var hashValue: Int {
//		return baseTime.hashValue
//	}
//}

// MARK: - Equatable

//extension RainLevels: Equatable {
//	public static func == (lhs: Tile, rhs: Tile) -> Bool {
//		return lhs.hashValue == rhs.hashValue
//	}
//}

// MARK: - CustomStringConvertible

//extension RainLevels: CustomStringConvertible {
//	public var description: String {
//		return baseTime.baseTimeString(atIndex: 0).flatMap { $0 + "\(coordinate.latitude)" + "\(coordinate.longitude)" } ?? "error"
//	}
//}

// MARK: - CustomDebugStringConvertible

//extension RainLevels: CustomDebugStringConvertible {
//	public var debugDescription: String {
//		var output: [String] = []
//
//		output.append("[url]: \(url)")
//		output.append(image != nil ? "[image]: not nil" : "[image]: nil")
//
//		return output.joined(separator: "\n")
//	}
//}
