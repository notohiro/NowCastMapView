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

        /// The `RainLevelsModel.Task` request object currently being handled by the task.
        public let request: Request

        /// The object is used to fetch `RainLevels`.
        public let baseTime: BaseTime

        /// The object that acts as the delegate of the `RainLevelsModel.Task`.
	    open private(set) weak var delegate: RainLevelsModelDelegate?

        /// The block to execute when the task completes.
	    open private(set) var completionHandler: ((Result) -> Void)?

        /// The `Tile`s to calculate `RainLevels` for specified conditions.
	    open private(set) var tiles = [Int: Tile]()

        /// A representation of the overall task state.
	    open private(set) var state = State.initialized

        /// The parent object of this `Task`
        public let model: RainLevelsModel

	    // MARK: - Private Properties

        private var tileModel: TileModel! // swiftlint:disable:this implicitly_unwrapped_optional

	    private var task: TileModel.Task! // swiftlint:disable:this implicitly_unwrapped_optional

	    private let semaphore = DispatchSemaphore(value: 1)

	    private let queue = OperationQueue()

	    // MARK: - Functions

        // Creates a task that retrieves the RainLevels of the specified conditions.
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

        // TODO: Test
        deinit {
            cancel()
        }

        /// Resumes the task, if it is suspended.
	    open func resume() {
    	    semaphore.wait()
    	    defer { semaphore.signal() }

    	    if state == .initialized { task.resume() }
    	    state = .processing
	    }

        /// Cancels the task.
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
	    private func finished(withResult result: Result) {
    	    if let delegate = delegate {
	    	    queue.addOperation {
    	    	    delegate.rainLevelsModel(self.model, task: self, result: result)
	    	    }
    	    }

    	    if let handler = completionHandler {
	    	    queue.addOperation {
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

public extension RainLevelsModel.Task {
    enum State {
	    case initialized
	    case processing
	    case canceled
	    case completed
    }
}

// MARK: - Static Functions

extension RainLevelsModel.Task {
    private static func makeRequest(range: CountableClosedRange<Int>, coordinate: CLLocationCoordinate2D) -> TileModel.Request {
	    let coordinates = Coordinates(origin: coordinate, terminal: coordinate)
	    let scale: MKZoomScale = 0.000_5
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

    	    if tiles.count != request.range.count {
	    	    return
    	    }

    	    let result: RainLevelsModel.Result

    	    do {
	    	    let rainLevels = try RainLevels(baseTime: baseTime, coordinate: request.coordinate, tiles: tiles)
	    	    result = RainLevelsModel.Result.succeeded(request: request, result: rainLevels)
    	    } catch let error as NCError {
	    	    result = RainLevelsModel.Result.failed(request: request, error: error)
    	    } catch {
	    	    result = RainLevelsModel.Result.failed(request: request, error: NCError.unknown)
    	    }

    	    state = .completed
    	    finished(withResult: result)
	    }
    }

    public func tileModel(_ model: TileModel, task: TileModel.Task, failed url: URL, error: Error) {
	    finished(withResult: RainLevelsModel.Result.failed(request: request, error: error))
    }
}

// MARK: - Hashable

extension RainLevelsModel.Task: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}

// MARK: - Equatable

extension RainLevelsModel.Task: Equatable {
    public static func == (lhs: RainLevelsModel.Task, rhs: RainLevelsModel.Task) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
