//
//  RainLevelsModel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public protocol RainLevelsProvider {
	func rainLevels(with request: RainLevelsModel.Request, completionHandler: ((RainLevelsModel.Result) -> Void)?) -> RainLevelsModel.Task
}

public protocol RainLevelsModelDelegate: class {
	func rainLevelsModel(_ model: RainLevelsModel, task: RainLevelsModel.Task, result: RainLevelsModel.Result)
}

open class RainLevelsModel: RainLevelsProvider {

	open private(set) weak var delegate: RainLevelsModelDelegate?

	open let baseTime: BaseTime

	open private(set) var tasks = [Task]()

	private let semaphore = DispatchSemaphore(value: 1)

	public init(baseTime: BaseTime, delegate: RainLevelsModelDelegate? = nil) {
		self.baseTime = baseTime
		self.delegate = delegate
	}

	deinit {
		tasks.forEach { $0.cancel() }
	}

	open func rainLevels(with request: Request, completionHandler: ((Result) -> Void)? = nil) -> Task {
		let task = Task(model: self, request: request, baseTime: baseTime, delegate: delegate, completionHandler: completionHandler)

		semaphore.wait()
		tasks.append(task)
		semaphore.signal()

		return task
	}

	func remove(_ task: Task) {
		semaphore.wait()
		defer { self.semaphore.signal() }

		guard let index = tasks.index(of: task) else {
			Logger.log(self, logLevel: .warning, message: "tasks.index(of:) failed.")
			return
		}

		tasks.remove(at: index)
	}
}
