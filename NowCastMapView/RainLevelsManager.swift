//
//  RainLevelsManager.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

// retain RainLevels Objects for processing request
class RainLevelsManager {
	static let sharedManager = RainLevelsManager()

	private var rainLevels = [RainLevels]()
	private let accessQueue = dispatch_queue_create("RainLevelsManagerAccess", DISPATCH_QUEUE_SERIAL)

	private init() { }

	func add(rainLevels: RainLevels) {
		dispatch_async(accessQueue) {
			self.rainLevels.append(rainLevels)
		}
	}

	func remove(rainLevels: RainLevels) {
		dispatch_async(accessQueue) {
			self.rainLevels = self.rainLevels.filter { $0 !== rainLevels }
		}
	}
}
