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

	private let semaphore = DispatchSemaphore(value: 1)

	public init?(baseTime: BaseTime, coordinate: CLLocationCoordinate2D, tiles: [Int : Tile]) {
		self.baseTime = baseTime
		self.coordinate = coordinate
		self.tiles = tiles

		if !TileModel.isServiceAvailable(at: coordinate) { return nil }

		guard let levels = calculate() else {
			Logger.log(logLevel: .error, message: "RainLevels.init() failed")
			return nil
		}
		self.levels = levels
	}

	private func calculate() -> [Int : RainLevel]? {
		var rainLevels = [Int: RainLevel]()
		var failed = false

		let queue = OperationQueue()
		queue.qualityOfService = .background

		tiles.forEach { (index, tile) in
			queue.addOperation {
				guard let rgba255 = tile.rgba255(at: self.coordinate) else {
					Logger.log(logLevel: .error, message: "Tile.rgba255(at:) failed. coordinate: \(self.coordinate)")

					self.semaphore.wait()
					failed = true
					self.semaphore.signal()

					return
				}

				guard let rainLevel = RainLevel(rgba255: rgba255) else {
					Logger.log(logLevel: .error, message: "RainLevel(rgba255:) failed. rgba255: \(rgba255)")

					self.semaphore.wait()
					failed = true
					self.semaphore.signal()

					return
				}

				self.semaphore.wait()
				rainLevels[index] = rainLevel
				self.semaphore.signal()
			}
		}

		queue.waitUntilAllOperationsAreFinished()

		return failed ? nil : rainLevels
	}
}
