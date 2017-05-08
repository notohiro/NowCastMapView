//
//  TileCache.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/05/07.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import Foundation

/**
A `TileCacheProvider` protocol defines a way to request a `Tile`.
*/
public protocol TileCacheProvider {

	var baseTime: BaseTime { get }

	/**
	Returns tiles within given MapRect. The `Tile.image` object will be nil if it's not downloaded.
	Call `resume()` method to obtain image file from internet.

	- Parameter	request:	The request you need to get tiles.

	- Returns: The tiles within given request.
	*/
	func tiles(with request: TileModel.Request) -> [Tile]
}

open class TileCache {
	public let baseTime: BaseTime

	public var cache = Set<Tile>()
	public var cacheByURL = [URL: Tile]()

	lazy open private(set) var model: TileModel = TileModel(baseTime: self.baseTime, delegate: self)

	open private(set) weak var delegate: TileModelDelegate?

	fileprivate let semaphore = DispatchSemaphore(value: 1)

	deinit {
		model.cancelAll()
	}

	init(baseTime: BaseTime, delegate: TileModelDelegate?) {
		self.baseTime = baseTime
		self.delegate = delegate
	}

}

extension TileCache: TileCacheProvider {
	open func tiles(with request: TileModel.Request) -> [Tile] {
		var ret = [Tile]()
		var needsRequest = false

		guard let newCoordinates = request.coordinates.intersecting(TileModel.serviceAreaCoordinates) else { return ret }

		let newRequest = TileModel.Request(range: request.range,
		                                   scale: request.scale,
		                                   coordinates: newCoordinates,
		                                   withoutProcessing: request.withoutProcessing)

		let zoomLevel = ZoomLevel(zoomScale: request.scale)

		guard let originModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: newRequest.coordinates.origin) else {
			var message = "Tile.Modifiers.init() failed. "
			message += "zoomLevel: \(zoomLevel) coordinate: \(newRequest.coordinates.origin)"
			Logger.log(self, logLevel: .warning, message: message)

			return ret
		}

		guard let terminalModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: newRequest.coordinates.terminal) else {
			var message = "Tile.Modifiers.init() failed. "
			message += "zoomLevel: \(zoomLevel) coordinate: \(newRequest.coordinates.origin)"
			Logger.log(self, logLevel: .warning, message: message)

			return ret
		}

		for index in request.range {
			for latMod in originModifiers.latitude ... terminalModifiers.latitude {
				for lonMod in originModifiers.longitude ... terminalModifiers.longitude {
					guard let mods = Tile.Modifiers(zoomLevel: zoomLevel, latitude: latMod, longitude: lonMod) else {
						var message = "Tile.Modifiers.init() failed. "
						message += "zoomLevel: \(zoomLevel) latitude: \(latMod) longitude: \(lonMod)"
						Logger.log(self, logLevel: .warning, message: message)

						continue
					}

					guard let url = URL(baseTime: baseTime, index: index, modifiers: mods) else {
						let message = "URL.init() failed. baseTime: \(baseTime) index: \(index) modifiers: \(mods)"
						Logger.log(self, logLevel: .warning, message: message)

						continue
					}

					if let cachedTile = cacheByURL[url] {
						ret.append(cachedTile)
					} else {
						needsRequest = true
					}
				}
			}
		}

		if needsRequest {
			let newRequest = TileModel.Request(range: request.range,
			                                   scale: request.scale,
			                                   coordinates: request.coordinates,
			                                   withoutProcessing: true)
			let task = model.tiles(with: newRequest, completionHandler: nil)
			task.resume()
		}

		return ret
	}
}

extension TileCache: TileModelDelegate {
	public func tileModel(_ model: TileModel, task: TileModel.Task, added tile: Tile) {
		semaphore.wait()
		cache.insert(tile)
		cacheByURL[tile.url] = tile
		semaphore.signal()

		delegate?.tileModel(model, task: task, added: tile)
	}

	public func tileModel(_ model: TileModel, task: TileModel.Task, failed tile: Tile) {
		delegate?.tileModel(model, task: task, failed: tile)
	}
}
