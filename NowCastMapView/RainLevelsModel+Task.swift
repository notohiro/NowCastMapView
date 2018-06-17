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

	    open private(set) var tiles = [Int: Tile]()

	    open private(set) var state = State.initialized

	    open let model: RainLevelsModel

	    // MARK: - Private Properties

	    private var tileModel: TileModel!

	    private var task: TileModel.Task!

	    private let semaphore = DispatchSemaphore(value: 1)

	    private let queue = OperationQueue()

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

extension RainLevelsModel.Task: Hashable { }

public extension RainLevelsModel.Task {
    static func == (lhs: RainLevelsModel.Task, rhs: RainLevelsModel.Task) -> Bool {
	    return lhs.hashValue == rhs.hashValue
    }

    static func != (lhs: RainLevelsModel.Task, rhs: RainLevelsModel.Task) -> Bool {
	    return !(lhs == rhs)
    }
}
