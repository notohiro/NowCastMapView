//
//  RainLevelsModel+Task.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/05/04.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import MapKit

extension RainLevelsModel {
	open class Task {

		// MARK: - Public Properties

		open let request: Request

		open let baseTime: BaseTime

		open private(set) weak var delegate: RainLevelsModelDelegate?

		open let hashValue = Date().hashValue

		open private(set) var completionHandler: ((Result) -> Void)?

		open fileprivate(set) var tiles = [Int: Tile]()

		open fileprivate(set) var state = State.initialized

		open let model: RainLevelsModel

		// MARK: - Private Properties

		private var tileModel: TileModel!

		private var task: TileModel.Task!

		fileprivate let semaphore = DispatchSemaphore(value: 1)

		// MARK: - Functions

		public init(model: RainLevelsModel,
		            request: Request,
		            baseTime: BaseTime,
		            delegate: RainLevelsModelDelegate?,
		            completionHandler: ((Result) -> Void)?) throws {
			self.model = model
			self.request = request
			self.baseTime = baseTime
			self.delegate = delegate
			self.completionHandler = completionHandler

			tileModel = TileModel(baseTime: self.baseTime, delegate: self)

			let tileRequest = Task.makeRequest(range: request.range, coordinate: request.coordinate)
			task = try tileModel.tiles(with: tileRequest, completionHandler: nil)
		}

		open func resume() {
			semaphore.wait()
			defer { semaphore.signal() }

			if state == .initialized { task.resume() }
			state = .processing
		}

		open func cancel() {
			semaphore.wait()
			defer { semaphore.signal() }

			if state == .initialized || state == .processing {
				state = .canceled

				tileModel.cancelAll()
				finalizeTask()
			}
		}

		// MARK: - Private Functions

		// should be called only once per instance and within semaphore
		fileprivate func finished(withResult result: Result) {
			if let delegate = delegate {
				OperationQueue().addOperation {
					delegate.rainLevelsModel(self.model, task: self, result: result)
				}
			}

			if let handler = completionHandler {
				OperationQueue().addOperation {
					handler(result)
				}
			}

			finalizeTask()
		}

		// should be called only once per instance and within semaphore
		private func finalizeTask() {
			delegate = nil
			completionHandler = nil
			model.remove(self)
		}
	}
}

extension RainLevelsModel.Task {
	public enum State {
		case initialized
		case processing
		case canceled
		case completed
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
		defer { semaphore.signal() }

		if state == .processing {
			tiles[tile.index] = tile

			if task.processingTiles.count != 0 {
				return
			}

			let result: RainLevelsModel.Result

			if tiles.count != request.range.count {
				let error = NCError.rainLevelsProcessingFailed(reason: .tileDownloadingFailed)
				result = RainLevelsModel.Result.failed(request: request, error: error)
			} else {
				do {
					let rainLevels = try RainLevels(baseTime: baseTime, coordinate: request.coordinate, tiles: tiles)
					result = RainLevelsModel.Result.succeeded(request: request, result: rainLevels)
				} catch let error as NCError {
					result = RainLevelsModel.Result.failed(request: request, error: error)
				} catch {
					result = RainLevelsModel.Result.failed(request: request, error: NCError.unknown)
				}
			}

			state = .completed
			finished(withResult: result)
		}
	}

	public func tileModel(_ model: TileModel, task: TileModel.Task, failed tile: Tile) {
		let error = NCError.rainLevelsProcessingFailed(reason: .tileDownloadingFailed)
		finished(withResult: RainLevelsModel.Result.failed(request: request, error: error))
	}
}

// MARK: - Hashable

extension RainLevelsModel.Task: Hashable { }

extension RainLevelsModel.Task {
	public static func == (lhs: RainLevelsModel.Task, rhs: RainLevelsModel.Task) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}

	public static func != (lhs: RainLevelsModel.Task, rhs: RainLevelsModel.Task) -> Bool {
		return !(lhs == rhs)
	}
}
