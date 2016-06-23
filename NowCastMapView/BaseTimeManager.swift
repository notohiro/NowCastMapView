//
//  BaseTimeManager.swift
//  MapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import AwesomeCache

public class BaseTimeManagerNotificationObject {
	public let baseTime: BaseTime
	public let fetchResult: NSComparisonResult
	private init(baseTime: BaseTime, fetchResult: NSComparisonResult) {
		self.baseTime = baseTime
		self.fetchResult = fetchResult
	}
}

final public class BaseTimeManager {
	struct Constants {
		static let baseTimeURL = NSURL(string: "http://www.jma.go.jp/jp/highresorad/highresorad_tile/tile_basetime.xml")!
		static let lastSavedBaseTimeKey = "lastSavedBaseTime"
	}

	public static let sharedManager = BaseTimeManager()

	public struct Notification {
		public static let name = "BaseTimeManagerNotification"
		public static let object = "object"
	}

	private var fetching = false
	private var timer: NSTimer?
	private let sharedCache = try! Cache<BaseTime>(name: "BaseTimeCache") // swiftlint:disable:this force_try

	public var fetchInterval: NSTimeInterval = 0 { // 0 means never check automatically
		didSet {
			timer?.invalidate()
			if fetchInterval != 0 {
				timer = NSTimer.scheduledTimerWithTimeInterval(fetchInterval,
				                                               target: self,
				                                               selector: #selector(BaseTimeManager.fetch(_:)),
				                                               userInfo: nil,
				                                               repeats: true)
			}
		}
	}

	public var lastSavedBaseTime: BaseTime? {
		return sharedCache.objectForKey(Constants.lastSavedBaseTimeKey)
	}

	private init() { }

	dynamic public func fetch(timer: NSTimer) { fetch() }

	public func fetch() {
		objc_sync_enter(self)
		if fetching {
			return
		} else {
			fetching = true
		}
		objc_sync_exit(self)

		let task = baseTimeSession.dataTaskWithURL(Constants.baseTimeURL) { [unowned self] data, response, error in
			if let _ = error { // do something?
			} else {
				let _ = data.flatMap { BaseTime(baseTimeData: $0) }.flatMap { self.notifyBaseTime($0) }
			}

			self.fetching = false
		}
		task.priority = NSURLSessionTaskPriorityHigh
		task.resume()
	}

	public func removeCache() {
		sharedCache.removeObjectForKey(Constants.lastSavedBaseTimeKey)
	}

	private func notifyBaseTime(baseTime: BaseTime) {
		// if lastSaved == nil, result = Ascending
		let fetchResult = lastSavedBaseTime?.compare(baseTime) ?? .OrderedAscending
		if fetchResult == .OrderedAscending { saveBaseTime(baseTime) }

		var notifyObject = [NSObject : AnyObject]()
		let aObject = BaseTimeManagerNotificationObject(baseTime: baseTime, fetchResult: fetchResult)
		notifyObject[BaseTimeManager.Notification.object] = aObject

		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(BaseTimeManager.Notification.name, object: nil, userInfo:notifyObject)
	}

	// for calling from test methods
	func saveBaseTime(baseTime: BaseTime) {
		sharedCache.setObject(baseTime, forKey: Constants.lastSavedBaseTimeKey)
	}
}
