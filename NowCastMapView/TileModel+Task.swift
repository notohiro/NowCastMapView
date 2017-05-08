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

		open private(set) var currentRequest: Request?

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

		// MARK: - Functions

		public init(model: TileModel,
		            request: Request,
		            baseTime: BaseTime,
		            delegate: TileModelDelegate?,
		            completionHandler: (([Tile]) -> Void)?) {
			self.model = model
			self.originalRequest = request
			self.baseTime = baseTime
			self.delegate = delegate
			self.completionHandler = completionHandler

			let configuration = URLSessionConfiguration.default
			configuration.httpMaximumConnectionsPerHost = 4
			let session = URLSession(configuration: configuration)
			self.session = session

			guard let newCoordinates = request.coordinates.intersecting(TileModel.serviceAreaCoordinates) else { return }

			currentRequest = TileModel.Request(range: request.range,
			                                   scale: request.scale,
			                                   coordinates: newCoordinates,
			                                   withoutProcessing: request.withoutProcessing)

			configureTasks()
		}

		public func resume() {
			semaphore.wait()

			if state == .initialized && processingTiles.count == 0 {
				state = .completed

				if let handler = completionHandler {
					OperationQueue().addOperation {
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

			semaphore.signal()
		}

		public func invalidateAndCancel() {
			semaphore.wait()

			if state == .initialized || state == .processing {
				state = .canceled

				finalizeTask()
			}

			semaphore.signal()
		}

		// MARK: - Private Functions

		private func configureTasks() {
			guard let currentRequest = self.currentRequest else { return }

			let zoomLevel = ZoomLevel(zoomScale: currentRequest.scale)

			guard let originModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: currentRequest.coordinates.origin) else {
				var message = "Tile.Modifiers.init() failed. "
				message += "zoomLevel: \(zoomLevel) coordinate: \(currentRequest.coordinates.origin)"
				Logger.log(self, logLevel: .warning, message: message)

				return
			}

			guard let terminalModifiers = Tile.Modifiers(zoomLevel: zoomLevel, coordinate: currentRequest.coordinates.terminal) else {
				var message = "Tile.Modifiers.init() failed. "
				message += "zoomLevel: \(zoomLevel) coordinate: \(currentRequest.coordinates.origin)"
				Logger.log(self, logLevel: .warning, message: message)

				return
			}

			for index in currentRequest.range {
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
			return session.dataTask(with: url) { data, _, _ in
				self.semaphore.wait()

				if self.state == .processing {
					guard var tile = self.processingTiles.removeValue(forKey: url) else {
						var message = "self.processingTiles.removeValue(forKey:) failed. "
						message += "url: \(url)"
						Logger.log(self, logLevel: .warning, message: message)

						self.semaphore.signal()
						return
					}

					guard let data = data else {
						// Network / URL failure
						return
					}

					guard let image = UIImage(data: data) else {
						var message = "UIImage(data:) failed. "
						message += "url: \(url)"
						Logger.log(self, logLevel: .warning, message: message)

						if let delegate = self.delegate {
							OperationQueue().addOperation {
								delegate.tileModel(self.model, task: self, failed: tile)
							}
						}

						self.semaphore.signal()
						return
					}

					tile.image = image
					self.completedTiles.append(tile)

					if let delegate = self.delegate {
						OperationQueue().addOperation {
							delegate.tileModel(self.model, task: self, added: tile)
						}
					}

					if self.processingTiles.count == 0 {
						self.state = .completed

						if let handler = self.completionHandler {
							OperationQueue().addOperation {
								handler(self.completedTiles)
							}
						}

						self.finalizeTask()
					}
				}

				self.semaphore.signal()
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
