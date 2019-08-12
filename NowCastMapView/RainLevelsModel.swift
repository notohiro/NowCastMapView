//
//  RainLevelsModel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit

public protocol RainLevelsProvider {
    // Creates `RainLevelsModel.Task` object that retrieves `RainLevels` of the specified conditions.
    func rainLevels(with request: RainLevelsModel.Request, completionHandler: ((RainLevelsModel.Result) -> Void)?) throws -> RainLevelsModel.Task
}

public protocol RainLevelsModelDelegate: AnyObject {
    // Tells the delegate that a task completes with result.
    func rainLevelsModel(_ model: RainLevelsModel, task: RainLevelsModel.Task, result: RainLevelsModel.Result)
}

open class RainLevelsModel: RainLevelsProvider {
    open private(set) weak var delegate: RainLevelsModelDelegate?

    public let baseTime: BaseTime

    open private(set) var tasks: Set<Task> = []

    private let semaphore = DispatchSemaphore(value: 1)

    public init(baseTime: BaseTime, delegate: RainLevelsModelDelegate? = nil) {
	    self.baseTime = baseTime
	    self.delegate = delegate
    }

    deinit {
	    tasks.forEach { $0.cancel() }
    }

    open func rainLevels(with request: Request, completionHandler: ((Result) -> Void)? = nil) throws -> Task {
	    let task = try Task(model: self,
	                        request: request,
	                        baseTime: baseTime,
	                        delegate: delegate,
	                        completionHandler: completionHandler)

	    semaphore.wait()
        tasks.insert(task)
	    semaphore.signal()

	    return task
    }

    internal func remove(_ task: Task) {
	    semaphore.wait()
	    defer { self.semaphore.signal() }

	    tasks.remove(task)
    }
}
