//
//  NowCastBaseTimeManager.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import AwesomeCache

private let kBaseTimeURL = NSURL(string: "http://www.jma.go.jp/jp/highresorad/highresorad_tile/tile_basetime.xml")!
private let kLastSavedBaseTimeKey = "lastSavedBaseTime"

public class NowCastBaseTimeManagerNotificationObject {
	public let baseTime: NowCastBaseTime
	public let fetchResult: NSComparisonResult
	private init(baseTime: NowCastBaseTime, fetchResult: NSComparisonResult) {
		self.baseTime = baseTime
		self.fetchResult = fetchResult
	}
}

let NowCastBaseTimeCacheName = "NowCastBaseTimeCache"

final public class NowCastBaseTimeManager {
	public static let sharedManager = NowCastBaseTimeManager()

	public struct Notification {
		public static let name = "NowCastBaseTimeManagerNotification"
		public static let object = "object"
	}
	
	private var fetching = false
	private var timer: NSTimer?
	private let sharedCache = try! Cache<NowCastBaseTime>(name: NowCastBaseTimeCacheName)

	public var fetchInterval: NSTimeInterval = 0 { // 0 means never check automatically
		didSet {
			timer?.invalidate()
			if self.fetchInterval != 0 {
				timer = NSTimer.scheduledTimerWithTimeInterval(fetchInterval, target: self, selector: #selector(NowCastBaseTimeManager.fetch(_:)), userInfo: nil, repeats: true)
			}
		}
	}

	public var lastSavedBaseTime: NowCastBaseTime? {
		return sharedCache.objectForKey(kLastSavedBaseTimeKey)
	}

	private init() { }

	dynamic public func fetch(timer: NSTimer) { fetch() }

	public func fetch() {
		objc_sync_enter(self)
		if (fetching) { return }
		else { fetching = true }
		objc_sync_exit(self)

		let task = baseTimeSession.dataTaskWithURL(kBaseTimeURL) { [unowned self] data, response, error in
			if let _ = error {	} // do something?
			else { let _ = data.flatMap{ NowCastBaseTime(baseTimeData: $0) }.flatMap { self.notifyBaseTime($0) } }

			self.fetching = false
		}
		task.priority = NSURLSessionTaskPriorityHigh
		task.resume()
	}

	public func removeCache() {
		sharedCache.removeObjectForKey(kLastSavedBaseTimeKey)
	}

	private func notifyBaseTime(baseTime: NowCastBaseTime) {
		// if lastSaved == nil, result = Ascending
		let fetchResult = lastSavedBaseTime?.compare(baseTime) ?? .OrderedAscending
		if fetchResult == .OrderedAscending { self.saveBaseTime(baseTime) }

		var notifyObject = [NSObject : AnyObject]()
		let aObject = NowCastBaseTimeManagerNotificationObject(baseTime: baseTime, fetchResult: fetchResult)
		notifyObject[NowCastBaseTimeManager.Notification.object] = aObject

		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(NowCastBaseTimeManager.Notification.name, object: nil, userInfo:notifyObject)
	}

	// for calling from test methods
	func saveBaseTime(baseTime: NowCastBaseTime) {
		sharedCache.setObject(baseTime, forKey: kLastSavedBaseTimeKey)
	}
}
