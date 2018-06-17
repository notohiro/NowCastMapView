//
//  RainLevels.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/1/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import CoreLocation
import Foundation

public struct RainLevels {
    public let baseTime: BaseTime
    public let coordinate: CLLocationCoordinate2D
    public let tiles: [Int: Tile]
    public private(set) var levels = [Int: RainLevel]()

    private let semaphore = DispatchSemaphore(value: 1)

    public init(baseTime: BaseTime, coordinate: CLLocationCoordinate2D, tiles: [Int: Tile]) throws {
	    self.baseTime = baseTime
	    self.coordinate = coordinate
	    self.tiles = tiles

	    if !TileModel.isServiceAvailable(at: coordinate) { throw NCError.outOfService }

	    self.levels = try calculate()
    }

    private func calculate() throws -> [Int: RainLevel] {
	    var rainLevels = [Int: RainLevel]()
	    var error: Error?

	    let queue = OperationQueue()
	    queue.qualityOfService = .background

	    tiles.forEach { index, tile in
    	    queue.addOperation {
	    	    guard let rgba255 = tile.rgba255(at: self.coordinate) else {
    	    	    self.semaphore.wait()
    	    	    error = NCError.rainLevelsFailed(reason: .tileInvalid)
    	    	    self.semaphore.signal()

    	    	    return
	    	    }

	    	    guard let rainLevel = RainLevel(rgba255: rgba255) else {
    	    	    self.semaphore.wait()
    	    	    error = NCError.rainLevelsFailed(reason: .colorInvalid(color: rgba255))
    	    	    self.semaphore.signal()

    	    	    return
	    	    }

	    	    self.semaphore.wait()
	    	    rainLevels[index] = rainLevel
	    	    self.semaphore.signal()
    	    }
	    }

	    queue.waitUntilAllOperationsAreFinished()

	    if let error = error {
    	    throw error
	    }

	    return rainLevels
    }
}
