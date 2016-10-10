//
//  RainLevelsModel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public protocol RainLevelsProvider {
	func rainLevels(with request: RainLevelsModel.Request) -> RainLevels?
}

public protocol RainLevelsModelDelegate: class {
	func rainLevelsModel(_ model: RainLevelsModel, added rainLevels: RainLevels)
	func rainLevelsModel(_ model: RainLevelsModel, failed request: RainLevelsModel.Request)
}

open class RainLevelsModel: RainLevelsProvider {

	open weak var delegate: RainLevelsModelDelegate?

	open let baseTime: BaseTime
	/// `processingRequests` contains requests including even not initialized request
	open var processingRequests = Set<Request>()
	/// `processingModels` contains only initialized requests
	fileprivate var processingModels = [Request : TileModel]()

	private var rainLevels = [Request : RainLevels]()

	private let tileQueue = OperationQueue()

	public init(baseTime: BaseTime) {
		self.baseTime = baseTime
		tileQueue.maxConcurrentOperationCount = 2
	}

	deinit {
		processingModels.forEach { (request, model) in failed(request: request) }
	}

	public func rainLevels(with request: Request) -> RainLevels? {
		var processTiles = false

		objc_sync_enter(self)
		let retVal = rainLevels[request]
		if retVal == nil {
			if !processingRequests.contains(request) {
				processTiles = true
				processingRequests.insert(request)
			}
		}
		objc_sync_exit(self)

		if processTiles {
			tileQueue.addOperation {
				let model = TileModel(baseTime: self.baseTime)
				model.delegate = self

				for index in request.range {

					let tileRequest = RainLevelsModel.makeRequest(index: index, coordinate: request.coordinate)
					if model.tiles(with: tileRequest).first == nil {
						self.failed(request: request)
						return
					}
				}

				self.processingModels[request] = model
				model.resume()
			}
		}

		return retVal
	}

	fileprivate func failed(request: Request) {
		if processingRequests.contains(request) {
			processingRequests.remove(request)
			processingModels.removeValue(forKey: request)

			delegate?.rainLevelsModel(self, failed: request)
			processingModels[request]?.cancel()
		}
	}

	fileprivate static func makeRequest(index: Int, coordinate: CLLocationCoordinate2D) -> TileModel.Request {
		let coordinates = Coordinates(origin: coordinate, terminal: coordinate)
		let scale: MKZoomScale = 0.0005
		return TileModel.Request(index: index, scale: scale, coordinates: coordinates)
	}
}

// MARK: - TileModelDelegate

extension RainLevelsModel: TileModelDelegate {
	public func tileModel(_ model: TileModel, added tiles: Set<Tile>) {
		if model.processingTiles.count == 0 {
			let requests = processingModels.filter { (_, processingModel) in model === processingModel }
			requests.forEach { (request, processingModel) in
				var tiles = [Int : Tile]()
				for index in request.range {
					let tileRequest = RainLevelsModel.makeRequest(index: index, coordinate: request.coordinate)
					guard let tile = model.tiles(with: tileRequest).first else {
						failed(request: request)
						return
					}
					tiles[index] = tile
				}

				guard let rainLevels = RainLevels(baseTime: baseTime, coordinate: request.coordinate, tiles: tiles) else {
					failed(request: request)
					return
				}

				processingRequests.remove(request)
				processingModels.removeValue(forKey: request)
				delegate?.rainLevelsModel(self, added: rainLevels)
			}
		}
	}

	public func tileModel(_ model: TileModel, failed tile: Tile) {
		let requests = processingModels.filter { (_, processingModel) in model === processingModel }
		requests.forEach { (request, _) in failed(request: request) }
	}
}
