//
//  TileModel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 8/26/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public protocol TileProvider {
	func tiles(with request: TileModel.Request) -> [Tile]
}

public protocol TileAvailability {
	static func isServiceAvailable(within coordinates: Coordinates) -> Bool
	static func isServiceAvailable(at coordinate: CLLocationCoordinate2D) -> Bool
}

public protocol TileModelDelegate: class {
	func tileModel(_ model: TileModel, added tiles: Set<Tile>)
	func tileModel(_ model: TileModel, failed tile: Tile)
}

open class TileModel: TileProvider {

	open let baseTime: BaseTime
	private var session: URLSession
	open weak var delegate: TileModelDelegate?
	private var cachedTiles = Set<Tile>() {
		didSet {
			let addedTiles = cachedTiles.subtracting(oldValue)
			delegate?.tileModel(self, added: addedTiles)
		}
	}
	open var processingTiles = Set<Tile>()

	private static func initSession() -> URLSession {
		let configuration = URLSessionConfiguration.default
		configuration.httpMaximumConnectionsPerHost = 4
		return URLSession(configuration: configuration)
	}

	public init(baseTime: BaseTime) {
		self.baseTime = baseTime
		self.session = TileModel.initSession()
	}

	deinit {
		print("TileModel.deinit")
	}

	/**
	Returns tiles within given MapRect.

	- Parameter	request:	The request you need to get tiles.

	- Returns: The tiles within given request.
	*/
	open func tiles(with request: TileModel.Request) -> [Tile] {
		var retArr = [Tile]()

		if !TileModel.isServiceAvailable(within: request.coordinates) { return retArr }

		// convert from MKZoomScale to ZoomLevel
		let zoomLevel = ZoomLevel(zoomScale: request.scale)

		// get tile numbers
		guard let originModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: request.coordinates.origin) else { return retArr }
		guard let terminalModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: request.coordinates.terminal) else { return retArr }

		// loop from origin to terminal
		for latMod in originModifiers.latitude ... terminalModifiers.latitude {
			for lonMod in originModifiers.longitude ... terminalModifiers.longitude {
				// get URL of tile
				guard let mods = Tile.Modifiers(zoomLevel: zoomLevel, latitude: latMod, longitude: lonMod) else { continue }
				guard let url = URL(baseTime: baseTime, index: request.index, modifiers: mods) else { continue }

				objc_sync_enter(self)
				// check `cachedTiles`
				if let tile = (cachedTiles.filter { $0.url.absoluteString == url.absoluteString }.first) {
					retArr.append(tile)
					objc_sync_exit(self)
					continue
				}

				// no cache on `cachedTiles`
				// check processingTiles
				if let tile = (processingTiles.filter { $0.url.absoluteString == url.absoluteString }.first) {
					retArr.append(tile)
				} else {
					var tile = Tile(image: nil, baseTime: baseTime, index: request.index, modifiers: mods, url: url)

					tile.dataTask = session.dataTask(with: url) { data, response, error in
						objc_sync_enter(self)
						self.processingTiles.remove(tile)
						tile.dataTask = nil

						if let image = (data.flatMap { UIImage(data: $0) }) {
							// fetched image successfully
							tile.image = image
							self.cachedTiles.insert(tile)
						} else {
							self.delegate?.tileModel(self, failed: tile)
						}
						objc_sync_exit(self)
					}

					processingTiles.insert(tile)
					retArr.append(tile)
				}
				objc_sync_exit(self)
			}
		}

		return retArr
	}

	open func resume() {
		processingTiles.forEach { $0.dataTask?.resume() }
	}

	open func suspend() {
		processingTiles.forEach { $0.dataTask?.suspend() }
	}

	open func cancel() {
		// call `cancel()` for each tasks before `invalidateAndCancel()`.
		// `invalidateAndCancel()` never exec completionHandler of tasks before resumed.
		processingTiles.forEach { $0.dataTask?.cancel() }
		session.invalidateAndCancel()
		session = TileModel.initSession()
		processingTiles.removeAll()
	}
}

extension TileModel: TileAvailability {
	/**
	Returns the serivce availability within given MapRect.

	- Parameter mapRect:	The MapRect you want to know.

	- Returns: MapRect contains service area or not.
	*/
	open static func isServiceAvailable(within coordinates: Coordinates) -> Bool {
		if coordinates.origin.latitude >= Constants.terminalLatitude &&
			coordinates.terminal.latitude <= Constants.originLatitude &&
			coordinates.origin.longitude <= Constants.terminalLongitude &&
			coordinates.terminal.longitude >= Constants.originLongitude {
			return true
		} else {
			return false
		}
	}

	/**
	Returns the serivce availability at given coordinate.

	- Parameter coordinate:	The coordinate you want to know.

	- Returns: The service availability at coordinate.
	*/
	open static func isServiceAvailable(at coordinate: CLLocationCoordinate2D) -> Bool {
		if coordinate.latitude >= Constants.terminalLatitude &&
			coordinate.latitude <= Constants.originLatitude &&
			coordinate.longitude <= Constants.terminalLongitude &&
			coordinate.longitude >= Constants.originLongitude {
			return true
		} else {
			return false
		}
	}
}

extension TileModel {
	public struct Request {
		public let index: Int
		public let scale: MKZoomScale
		public let coordinates: Coordinates

		public init(index: Int, scale: MKZoomScale, coordinates: Coordinates) {
			self.index = index
			self.scale = scale
			self.coordinates = coordinates
		}
	}
}
