//
//  RainLevelsModel+Task.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/05/04.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import MapKit

extension RainLevelsModel {
	open class Task: Hashable {

		// MARK: - Public Properties

		public let request: Request

		public let baseTime: BaseTime

		public weak var delegate: RainLevelsModelDelegate?

		public var hashValue: Int

		// MARK: - Private Properties

		private let model: TileModel

		private let parent: RainLevelsModel

		fileprivate var completionHandler: ((Result) -> Void)?

		fileprivate var tiles = [Int: Tile]()

		private let queue = OperationQueue()

		private let lock = NSLock()

		// MARK: - Functions

		public init(parent: RainLevelsModel,
		            request: Request,
		            baseTime: BaseTime,
		            delegate: RainLevelsModelDelegate?,
		            completionHandler: ((Result) -> Void)?) {
			let model = TileModel(baseTime: baseTime)
			self.model = model
			self.parent = parent
			self.request = request
			self.baseTime = baseTime
			self.delegate = delegate
			self.completionHandler = completionHandler
			self.hashValue = Date().hashValue

			model.delegate = self
			queue.qualityOfService = .background

			queue.addOperation {
				for index in request.range {
					let tileRequest = Task.makeRequest(index: index, coordinate: request.coordinate)
					if model.tiles(with: tileRequest).count == 0 {
						self.finished(withResult: Result.failed(request: request))
						return
					}
				}

				model.resume()
			}
		}

		open func cancel() {
			model.cancel()
			finished(withResult: RainLevelsModel.Result.canceled(request: request))
		}

		// MARK: - Private Functions

		private static func makeRequest(index: Int, coordinate: CLLocationCoordinate2D) -> TileModel.Request {
			let coordinates = Coordinates(origin: coordinate, terminal: coordinate)
			let scale: MKZoomScale = 0.0005
			return TileModel.Request(index: index, scale: scale, coordinates: coordinates)
		}

		fileprivate func finished(withResult result: Result) {
			lock.lock()
			defer { self.lock.unlock() }

			delegate?.rainLevelsModel(parent, result: result)
			completionHandler?(result)

			delegate = nil
			completionHandler = nil

			parent.remove(self)
		}
	}
}

// MARK: - TileModelDelegate

extension RainLevelsModel.Task: TileModelDelegate {
	public func tileModel(_ model: TileModel, added tiles: Set<Tile>) {
		tiles.forEach { tile in
			self.tiles[tile.index] = tile
		}

		if model.processingTiles.count != 0 { return }

		if tiles.count != request.range.count {
			finished(withResult: RainLevelsModel.Result.failed(request: request))
			return
		}

		guard let rainLevels = RainLevels(baseTime: baseTime, coordinate: request.coordinate, tiles: self.tiles) else {
			finished(withResult: RainLevelsModel.Result.failed(request: request))
			return
		}

		finished(withResult: RainLevelsModel.Result.succeeded(request: request, result: rainLevels))
	}

	public func tileModel(_ model: TileModel, failed tile: Tile) {
		finished(withResult: RainLevelsModel.Result.failed(request: request))
	}
}

// MARK: - Hashable

extension RainLevelsModel.Task {
	public static func == (lhs: RainLevelsModel.Task, rhs: RainLevelsModel.Task) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}
