//
//  TileModel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 8/26/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

/**
A `TileProvider` protocol defines a way to request a `Tile`.
*/
public protocol TileProvider {
	/**
	Returns tiles within given MapRect. The `Tile.image` object will be nil if it's not downloaded.
	Call `resume()` method to obtain image file from internet.

	- Parameter	request:	The request you need to get tiles.

	- Returns: The tiles within given request.
	*/
	func tiles(with request: TileModel.Request) -> [Tile]
}

/**
A `TileAvailability` protocol defines a way to check the service availability.
*/
public protocol TileAvailability {
	/**
	Returns the serivce availability within given MapRect.

	- Parameter coordinates:	The `Coordinates` you want to know.

	- Returns: `Coordinates` contains service area or not.
	*/
	static func isServiceAvailable(within coordinates: Coordinates) -> Bool

	/**
	Returns the serivce availability at given coordinate.

	- Parameter coordinate:	The coordinate you want to know.

	- Returns: The service availability at coordinate.
	*/
	static func isServiceAvailable(at coordinate: CLLocationCoordinate2D) -> Bool
}

/**
The delegate of a `TileModel` object must adopt the `TileModelDelegate` protocol.
The `TileModelDelegate` protocol describes the methods that `TileModel` objects call on their delegates to handle requested events.
*/
public protocol TileModelDelegate: class {
	/// Tells the delegate that a request has finished and added tiles in model's cache.
	func tileModel(_ model: TileModel, added tiles: Set<Tile>)

	/// Tells the delegate that a request has finished with error.
	func tileModel(_ model: TileModel, failed tile: Tile)
}

/**
An `TileModel` object lets you load the `Tile` by providing a `Request` object.
*/
open class TileModel {

	// MARK: - Public Properties

	open let baseTime: BaseTime

	open weak var delegate: TileModelDelegate?

	open var processingTiles = Set<Tile>()

	// MARK: - Private Properties

	fileprivate var session: URLSession

	fileprivate var cachedTiles = Set<Tile>() {
		didSet {
			let addedTiles = cachedTiles.subtracting(oldValue)
			delegate?.tileModel(self, added: addedTiles)
		}
	}

	// MARK: - Functions

	public init(baseTime: BaseTime) {
		self.baseTime = baseTime
		self.session = TileModel.initSession()
	}

	/// Resumes the all tasks, if it is suspended.
	open func resume() {
		processingTiles.forEach { $0.dataTask?.resume() }
	}

	/// Suspend the all tasks, if it is suspended.
	open func suspend() {
		processingTiles.forEach { $0.dataTask?.suspend() }
	}

	/// Immediately cancel the all tasks. Delegate will be called if it's set.
	open func cancel() {
		// call `cancel()` for each tasks before `invalidateAndCancel()`.
		// `invalidateAndCancel()` never exec completionHandler of tasks before resumed.
		processingTiles.forEach { $0.dataTask?.cancel() }
		session.invalidateAndCancel()
		session = TileModel.initSession()
		processingTiles.removeAll()
	}

	// MARK: - Helper Functions

	private static func initSession() -> URLSession {
		let configuration = URLSessionConfiguration.default
		configuration.httpMaximumConnectionsPerHost = 4
		return URLSession(configuration: configuration)
	}
}

// MARK: - TileProvider

extension TileModel: TileProvider {
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
}

// MARK: - TileAvailability

extension TileModel: TileAvailability {
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
