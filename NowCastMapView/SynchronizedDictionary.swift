//
//  SynchronizedDictionary.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

class SynchronizedDictionary<S: Hashable, T> {
	private var _dictionary = [S : T]()
	var count: Int { return _dictionary.count }
	private let accessQueue = dispatch_queue_create("SynchronizedDictionaryAccess", DISPATCH_QUEUE_SERIAL)

	func setValue(value: T, forKey key: S) {
		dispatch_async(accessQueue) {
			self._dictionary[key] = value
		}
	}

	func valueForKey(key: S) -> T? {
		var value: T?
		dispatch_sync(accessQueue) {
			value = self._dictionary[key]
		}
		return value
	}

	func removeValueForKey(key: S) {
		dispatch_async(accessQueue) {
			self._dictionary.removeValueForKey(key)
		}
	}
}
