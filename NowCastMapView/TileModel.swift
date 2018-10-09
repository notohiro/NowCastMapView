//
//  TileModel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 8/26/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

/// A `TileProvider` protocol defines a way to request a `TileModel.Task`.
public protocol TileProvider {

    var baseTime: BaseTime { get }

    /// Returns task to obtain tiles within given MapRect.
    /// Call `resume()` method of returning value to obtain image from internet.
    ///
    /// - Parameters:
    ///   - request: The request you need to get tiles.
    ///   - completionHandler: The completion handler to call when the load request is complete.
    /// - Returns: The task to process given request.
    func tiles(with request: TileModel.Request, completionHandler: (([Tile]) -> Void)?) throws -> TileModel.Task
}

/// A `TileAvailability` protocol defines a way to check the service availability.
public protocol TileAvailability {

    /// Returns the serivce availability within given MapRect.
    ///
    /// - Parameter coordinates: The `Coordinates` you want to know.
    /// - Returns: `Coordinates` contains service area or not.
    static func isServiceAvailable(within coordinates: Coordinates) -> Bool

    /// Returns the serivce availability at given coordinate.
    ///
    /// - Parameter coordinate: The coordinate you want to know.
    /// - Returns: The service availability at coordinate.
    static func isServiceAvailable(at coordinate: CLLocationCoordinate2D) -> Bool
}

/// The delegate of a `TileModel` object must adopt the `TileModelDelegate` protocol.
/// The `TileModelDelegate` protocol describes the methods that `TileModel` objects
/// call on their delegates to handle requested events.
public protocol TileModelDelegate: class {
    /// Tells the delegate that a request has finished and added tiles in model's cache.
    func tileModel(_ model: TileModel, task: TileModel.Task, added tile: Tile)

    /// Tells the delegate that a request has finished with error.
    func tileModel(_ model: TileModel, task: TileModel.Task, failed url: URL, error: Error)
}

/// An `TileModel` object lets you load the `Tile` by providing a `Request` object.
open class TileModel {

    // MARK: - TileProvider

    public let baseTime: BaseTime

    // MARK: - Public Properties

    open private(set) var tasks = [Task]()

    open weak private(set) var delegate: TileModelDelegate?

    // MARK: - Private Properties

    private let semaphore = DispatchSemaphore(value: 1)

    // MARK: - Public Functions

    public init(baseTime: BaseTime, delegate: TileModelDelegate? = nil) {
	    self.baseTime = baseTime
	    self.delegate = delegate
    }

    public func cancelAll() {
	    let tasks = self.tasks

	    tasks.forEach { $0.invalidateAndCancel() }
    }

    // MARK: - Internal Functions

    internal func remove(_ task: Task) {
	    semaphore.wait()
	    defer { self.semaphore.signal() }

	    guard let index = tasks.index(of: task) else { return }
	    tasks.remove(at: index)
    }

    internal func isProcessing(_ tile: Tile) -> Bool {
	    // thread safe
	    let tasks = self.tasks

	    var processing = false
	    tasks.forEach { task in
    	    if task.processingTiles[tile.url] != nil { processing = true }
	    }

	    return processing
    }
}

// MARK: - TileProvider

extension TileModel: TileProvider {
    open func tiles(with request: TileModel.Request, completionHandler: (([Tile]) -> Void)?) throws -> Task {
	    semaphore.wait()
	    defer { semaphore.signal() }

        let task = try Task(model: self,
                            request: request,
                            baseTime: baseTime,
                            delegate: delegate,
                            completionHandler: completionHandler)
	    tasks.append(task)

	    return task
    }
}

// MARK: - TileAvailability

extension TileModel: TileAvailability {
    public static func isServiceAvailable(within coordinates: Coordinates) -> Bool {
	    if coordinates.origin.latitude >= Constants.terminalLatitude &&
    	    coordinates.terminal.latitude <= Constants.originLatitude &&
    	    coordinates.origin.longitude <= Constants.terminalLongitude &&
    	    coordinates.terminal.longitude >= Constants.originLongitude {
    	    return true
	    } else {
    	    return false
	    }
    }

    public static func isServiceAvailable(at coordinate: CLLocationCoordinate2D) -> Bool {
	    if coordinate.latitude >= Constants.terminalLatitude &&
    	    coordinate.latitude <= Constants.originLatitude &&
    	    coordinate.longitude <= Constants.terminalLongitude &&
    	    coordinate.longitude >= Constants.originLongitude {
    	    return true
	    } else {
    	    return false
	    }
    }

    public static var serviceAreaMapRect: MKMapRect {
	    return MKMapRect(coordinates: TileModel.serviceAreaCoordinates)
    }

    public static var serviceAreaCoordinates: Coordinates {
	    let origin = CLLocationCoordinate2DMake(Constants.originLatitude, Constants.originLongitude)
	    let terminal = CLLocationCoordinate2DMake(Constants.terminalLatitude, Constants.terminalLongitude)
	    return Coordinates(origin: origin, terminal: terminal)
    }
}
