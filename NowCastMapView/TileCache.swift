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

    - Parameter    request:    The request you need to get tiles.

    - Returns: The tiles within given request.
    */
    func tiles(with request: TileModel.Request) throws -> [Tile]
}

open class TileCache {
    public let baseTime: BaseTime

    public var cache = Set<Tile>()
    public var cacheByURL = [URL: Tile]()

    lazy open private(set) var model: TileModel = TileModel(baseTime: self.baseTime, delegate: self)

    open private(set) weak var delegate: TileModelDelegate?

    private let semaphore = DispatchSemaphore(value: 1)

    deinit {
	    model.cancelAll()
    }

    internal init(baseTime: BaseTime, delegate: TileModelDelegate?) {
	    self.baseTime = baseTime
	    self.delegate = delegate
    }

}

extension TileCache: TileCacheProvider {
    open func tiles(with request: TileModel.Request) throws -> [Tile] {
	    var ret = [Tile]()
	    var needsRequest = false

	    guard let newCoordinates = request.coordinates.intersecting(TileModel.serviceAreaCoordinates) else {
    	    throw NCError.outOfService
	    }

	    let newRequest = TileModel.Request(range: request.range,
	                                       scale: request.scale,
	                                       coordinates: newCoordinates,
	                                       withoutProcessing: request.withoutProcessing)

	    let zoomLevel = ZoomLevel(zoomScale: request.scale)

	    guard let originModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: newRequest.coordinates.origin) else {
    	    let reason = NCError.TileFailedReason.modifiersInitializationFailedCoordinate(zoomLevel: zoomLevel, coordinate: newRequest.coordinates.origin)
    	    throw NCError.tileFailed(reason: reason)
	    }

	    guard let terminalModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: newRequest.coordinates.terminal) else {
    	    let reason = NCError.TileFailedReason.modifiersInitializationFailedCoordinate(zoomLevel: zoomLevel, coordinate: newRequest.coordinates.terminal)
    	    throw NCError.tileFailed(reason: reason)
	    }

	    for index in request.range {
    	    for latMod in originModifiers.latitude ... terminalModifiers.latitude {
	    	    for lonMod in originModifiers.longitude ... terminalModifiers.longitude {
    	    	    guard let mods = Tile.Modifiers(zoomLevel: zoomLevel, latitude: latMod, longitude: lonMod) else {
	    	    	    let reason = NCError.TileFailedReason.modifiersInitializationFailedMods(zoomLevel: zoomLevel, latitiude: latMod, longitude: lonMod)
	    	    	    throw NCError.tileFailed(reason: reason)
    	    	    }

    	    	    guard let url = URL(baseTime: baseTime, index: index, modifiers: mods) else {
	    	    	    throw NCError.tileFailed(reason: .urlInitializationFailed)
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
    	    let task = try model.tiles(with: newRequest, completionHandler: nil)
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

    public func tileModel(_ model: TileModel, task: TileModel.Task, failed url: URL, error: Error) {
	    delegate?.tileModel(model, task: task, failed: url, error: error)
    }
}
