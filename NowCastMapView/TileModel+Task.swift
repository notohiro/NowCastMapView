//
//  TileModel+Task.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/05/06.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension TileModel {
	open class Task {

		// MARK: - Public Properties

		open private(set) var originalRequest: Request

		open private(set) var currentRequest: Request

		open let baseTime: BaseTime

		open private(set) weak var delegate: TileModelDelegate?

		open private(set) var processingTiles = [URL: Tile]()

		open private(set) var completedTiles = [Tile]()

		open private(set) var state = State.initialized

		open let model: TileModel

		open private(set) var completionHandler: (([Tile]) -> Void)?

		open let hashValue = Date().hashValue

		// MARK: - Private Properties

		private var session: URLSession

		private var suspendedTasks = [URLSessionTask]()

		private let semaphore = DispatchSemaphore(value: 1)

		private let queue = OperationQueue()

		// MARK: - Functions

		public init(model: TileModel,
		            request: Request,
		            baseTime: BaseTime,
		            delegate: TileModelDelegate?,
		            completionHandler: (([Tile]) -> Void)?) throws {
			self.model = model
			self.originalRequest = request
			self.baseTime = baseTime
			self.delegate = delegate
			self.completionHandler = completionHandler

			let configuration = URLSessionConfiguration.default
			configuration.httpMaximumConnectionsPerHost = 4
			let session = URLSession(configuration: configuration)
			self.session = session

			guard let newCoordinates = request.coordinates.intersecting(TileModel.serviceAreaCoordinates) else {
				throw NCError.outOfService
			}

			currentRequest = TileModel.Request(range: request.range,
			                                   scale: request.scale,
			                                   coordinates: newCoordinates,
			                                   withoutProcessing: request.withoutProcessing)

			try configureTasks()
		}

		public func resume() {
			semaphore.wait()
			defer { semaphore.signal() }

			if state == .initialized && processingTiles.count == 0 {
				state = .completed

				if let handler = completionHandler {
					queue.addOperation {
						handler(self.completedTiles)
					}
				}

				finalizeTask()
			} else if state == .initialized {
				state = .processing

				while suspendedTasks.count > 0 {
					let task = suspendedTasks.removeFirst()
					task.resume()
				}
			}
		}

		public func invalidateAndCancel() {
			semaphore.wait()
			defer { semaphore.signal() }

			if state == .initialized || state == .processing {
				state = .canceled

				finalizeTask()
			}
		}

		// MARK: - Private Functions

		private func configureTasks() throws {
			let zoomLevel = ZoomLevel(zoomScale: currentRequest.scale)

			guard let originModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: currentRequest.coordinates.origin) else {
				let reason = NCError.TileFailedReason.modifiersInitializationFailedCoordinate(zoomLevel: zoomLevel, coordinate: currentRequest.coordinates.origin)
				throw NCError.tileFailed(reason: reason)
			}

			guard let terminalModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: currentRequest.coordinates.terminal) else {
				let reason = NCError.TileFailedReason.modifiersInitializationFailedCoordinate(zoomLevel: zoomLevel, coordinate: currentRequest.coordinates.terminal)
				throw NCError.tileFailed(reason: reason)
			}

			for index in currentRequest.range {
				for latMod in originModifiers.latitude ... terminalModifiers.latitude {
					for lonMod in originModifiers.longitude ... terminalModifiers.longitude {
						guard let mods = Tile.Modifiers(zoomLevel: zoomLevel, latitude: latMod, longitude: lonMod) else {
							let reason = NCError.TileFailedReason.modifiersInitializationFailedMods(zoomLevel: zoomLevel, latitiude: latMod, Longitude: lonMod)
							throw NCError.tileFailed(reason: reason)
						}

						guard let url = URL(baseTime: baseTime, index: index, modifiers: mods) else {
							throw NCError.tileFailed(reason: .urlInitializationFailed)
						}

						let tile = Tile(image: nil, baseTime: baseTime, index: index, modifiers: mods, url: url)

						if currentRequest.withoutProcessing && model.isProcessing(tile) { continue }

						suspendedTasks.append(makeDataTask(with: session, url: url))

						processingTiles[url] = tile
					}
				}
			}
		}

		// should be called only once per instance and within semaphore
		private func finalizeTask() {
			session.invalidateAndCancel()
			delegate = nil
			completionHandler = nil
			model.remove(self)
		}

		private func makeDataTask(with session: URLSession, url: URL) -> URLSessionDataTask {
			return session.dataTask(with: url) { data, _, sessionError in
				self.semaphore.wait()

				// process data only when state == .processing
				if self.state != .processing {
					self.semaphore.signal()
					return
				}

				var error: Error?

				defer {
					if let error = error, let delegate = self.delegate {
						self.queue.addOperation {
							delegate.tileModel(self.model, task: self, failed: url, error: error)
						}
					}

					if self.processingTiles.count == 0 {
						self.state = .completed

						if let handler = self.completionHandler {
							self.queue.addOperation {
								handler(self.completedTiles)
							}
						}

						self.finalizeTask()
					}

					self.semaphore.signal()
				}

				if let sessionError = sessionError {
					error = sessionError
					return
				}

				guard var tile = self.processingTiles.removeValue(forKey: url) else {
					error = NCError.tileFailed(reason: .internalError)
					return
				}

				guard let data = data, let image = UIImage(data: data) else {
					error = NCError.tileFailed(reason: .imageProcessingFailed)
					return
				}

				tile.image = image
				self.completedTiles.append(tile)

				if let delegate = self.delegate {
					self.queue.addOperation {
						delegate.tileModel(self.model, task: self, added: tile)
					}
				}
			}
		}
	}
}

extension TileModel.Task {
	public enum State {
		case initialized
		case processing
		case canceled
		case completed
	}
}

// MARK: - Hashable

extension TileModel.Task: Hashable { }

extension TileModel.Task: Equatable {
	public static func == (lhs: TileModel.Task, rhs: TileModel.Task) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}

	public static func != (lhs: TileModel.Task, rhs: TileModel.Task) -> Bool {
		return !(lhs == rhs)
	}
}
