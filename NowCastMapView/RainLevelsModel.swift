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
    func rainLevels(with request: RainLevelsModel.Request, completionHandler: ((RainLevelsModel.Result) -> Void)?) throws -> RainLevelsModel.Task
}

public protocol RainLevelsModelDelegate: class {
    func rainLevelsModel(_ model: RainLevelsModel, task: RainLevelsModel.Task, result: RainLevelsModel.Result)
}

open class RainLevelsModel: RainLevelsProvider {

    open private(set) weak var delegate: RainLevelsModelDelegate?

    public let baseTime: BaseTime

    open private(set) var tasks = [Task]()

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
	    tasks.append(task)
	    semaphore.signal()

	    return task
    }

    internal func remove(_ task: Task) {
	    semaphore.wait()
	    defer { self.semaphore.signal() }

	    guard let index = tasks.index(of: task) else { return }

	    tasks.remove(at: index)
    }
}
