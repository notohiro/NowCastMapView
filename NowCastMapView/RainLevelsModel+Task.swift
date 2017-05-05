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

		public private(set) weak var delegate: RainLevelsModelDelegate?

		public var hashValue: Int

		// MARK: - Private Properties

		lazy private var model: TileModel = TileModel(baseTime: self.baseTime, delegate: self)

		private let parent: RainLevelsModel

		fileprivate var completionHandler: ((Result) -> Void)?

		fileprivate var tiles = [Int: Tile]()

//		private let queue = OperationQueue()

		private var task: TileModel.Task?

		fileprivate let semaphore = DispatchSemaphore(value: 1)

		// MARK: - Functions

		public init(parent: RainLevelsModel,
		            request: Request,
		            baseTime: BaseTime,
		            delegate: RainLevelsModelDelegate?,
		            completionHandler: ((Result) -> Void)?) {
			self.parent = parent
			self.request = request
			self.baseTime = baseTime
			self.delegate = delegate
			self.completionHandler = completionHandler
			self.hashValue = Date().hashValue

//			queue.qualityOfService = .background

			// prevent cancel() before initialize operation will be copmleted
//			semaphore.wait()

			let tileRequest = Task.makeRequest(range: request.range, coordinate: request.coordinate)
			task = model.tiles(with: tileRequest, completionHandler: nil)
		}

		open func resume() {
			task?.resume()
		}

		open func cancel() {
//			semaphore.wait()
			model.cancelAll()
//			semaphore.signal()

//			finished(withResult: RainLevelsModel.Result.canceled(request: request))
		}

		// MARK: - Private Functions

		fileprivate func finished(withResult result: Result) {
			semaphore.wait()

			if let delegate = delegate {
				OperationQueue().addOperation {
					delegate.rainLevelsModel(self.parent, task: self, result: result)
				}
			}

			if let handler = completionHandler {
				OperationQueue().addOperation {
					handler(result)
				}
			}

			self.delegate = nil
			self.completionHandler = nil
			self.task = nil

			parent.remove(self)

			semaphore.signal()
		}
	}
}

// MARK: - Static Functions

extension RainLevelsModel.Task {
	fileprivate static func makeRequest(range: CountableClosedRange<Int>, coordinate: CLLocationCoordinate2D) -> TileModel.Request {
		let coordinates = Coordinates(origin: coordinate, terminal: coordinate)
		let scale: MKZoomScale = 0.0005
		return TileModel.Request(range: range, scale: scale, coordinates: coordinates)
	}
}

// MARK: - TileModelDelegate

extension RainLevelsModel.Task: TileModelDelegate {
	public func tileModel(_ model: TileModel, task: TileModel.Task, added tile: Tile) {
		semaphore.wait()
		tiles[tile.index] = tile
		semaphore.signal()

		if task.processingTiles.count != 0 { return }

		if tiles.count != request.range.count {
			finished(withResult: RainLevelsModel.Result.failed(request: request))
			return
		}

		guard let rainLevels = RainLevels(baseTime: baseTime, coordinate: request.coordinate, tiles: tiles) else {
			finished(withResult: RainLevelsModel.Result.failed(request: request))
			return
		}

		finished(withResult: RainLevelsModel.Result.succeeded(request: request, result: rainLevels))
	}

	public func tileModel(_ model: TileModel, task: TileModel.Task, failed tile: Tile) {
		finished(withResult: RainLevelsModel.Result.failed(request: request))
	}
}

// MARK: - Hashable

extension RainLevelsModel.Task {
	public static func == (lhs: RainLevelsModel.Task, rhs: RainLevelsModel.Task) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}
