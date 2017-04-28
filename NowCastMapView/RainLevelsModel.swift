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
	func rainLevels(with request: RainLevelsModel.Request, completionHandler: ((RainLevelsModel.Result) -> Void)?)
}

public protocol RainLevelsModelDelegate: class {
	func rainLevelsModel(_ model: RainLevelsModel, result: RainLevelsModel.Result)
}

open class RainLevelsModel: RainLevelsProvider {

	open weak var delegate: RainLevelsModelDelegate?

	open let baseTime: BaseTime

	/// `processingRequests` contains requests including even not initialized request
	open var processingRequests = Set<Request>()

	/// `processingModels` contains only initialized requests
	fileprivate var processingModels = [Request: TileModel]()

	fileprivate var completionHandlers = [Request: ((Result) -> Void)]()

	private var rainLevels = [Request: RainLevels]()

	private let tileQueue = OperationQueue()

	public init(baseTime: BaseTime) {
		self.baseTime = baseTime
		tileQueue.maxConcurrentOperationCount = 2
	}

	deinit {
		processingModels.forEach { (request, _) in finished(withResult: Result.failed(request: request)) }
	}

	public func rainLevels(with request: Request, completionHandler: ((Result) -> Void)? = nil) {
		if let handler = completionHandler {
			completionHandlers[request] = handler
		}

		if let rainLevels = rainLevels[request] {
			finished(withResult: Result.succeeded(request: request, result: rainLevels))
			return
		}

		if processingRequests.insert(request).inserted {
			tileQueue.addOperation {
				let model = TileModel(baseTime: self.baseTime)
				model.delegate = self

				for index in request.range {

					let tileRequest = RainLevelsModel.makeRequest(index: index, coordinate: request.coordinate)
					if model.tiles(with: tileRequest).first == nil {
						self.finished(withResult: Result.failed(request: request))
						return
					}
				}

				self.processingModels[request] = model
				model.resume()
			}
		}
	}

	public func cancel(_ request: Request) {
		finished(withResult: Result.canceled(request: request))
	}

	fileprivate func finished(withResult result: Result) {
		if processingRequests.remove(result.request) != nil {
			processingModels[result.request]?.cancel()
			processingModels.removeValue(forKey: result.request)

			delegate?.rainLevelsModel(self, result: result)

			completionHandlers[result.request]?(result)
			completionHandlers.removeValue(forKey: result.request)
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
			requests.forEach { (request, _) in
				var tiles = [Int: Tile]()
				for index in request.range {
					let tileRequest = RainLevelsModel.makeRequest(index: index, coordinate: request.coordinate)
					guard let tile = model.tiles(with: tileRequest).first else {
						finished(withResult: Result.failed(request: request))
						return
					}
					tiles[index] = tile
				}

				guard let rainLevels = RainLevels(baseTime: baseTime, coordinate: request.coordinate, tiles: tiles) else {
					finished(withResult: Result.failed(request: request))
					return
				}

				finished(withResult: Result.succeeded(request: request, result: rainLevels))
			}
		}
	}

	public func tileModel(_ model: TileModel, failed tile: Tile) {
		let requests = processingModels.filter { (_, processingModel) in model === processingModel }
		requests.forEach { (request, _) in finished(withResult: Result.failed(request: request)) }
	}
}
