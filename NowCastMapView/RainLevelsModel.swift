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
	func rainLevelsModel(_ model: RainLevelsModel, result: RainLevelsModel.Result)
}

open class RainLevelsModel: RainLevelsProvider {

	open weak var delegate: RainLevelsModelDelegate?

	open let baseTime: BaseTime

	open var tasks = [Task]()

	private let lock = NSLock()

	public init(baseTime: BaseTime) {
		self.baseTime = baseTime
	}

	deinit {
		tasks.forEach { $0.cancel() }
	}

	open func rainLevels(with request: Request, completionHandler: ((Result) -> Void)? = nil) -> Task {
		let task = Task(parent: self, request: request, baseTime: baseTime, delegate: delegate, completionHandler: completionHandler)
		tasks.append(task)

		return task
	}

	func remove(_ task: Task) {
		lock.lock()
		defer { self.lock.unlock() }

		guard let index = tasks.index(of: task) else { return }
		tasks.remove(at: index)
	}
}
