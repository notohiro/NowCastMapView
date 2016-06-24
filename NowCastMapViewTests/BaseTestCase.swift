//
//  BaseTestCase.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 5/14/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import XCTest

class BaseTestCase: XCTestCase {
	let secondsForTimeout = 3.0

	func getBaseTimeFrom(fileName: String) -> BaseTime? {
		let baseTime = NSBundle(forClass: self.dynamicType).pathForResource(fileName, ofType: "xml").flatMap {
			NSData(contentsOfFile: $0).flatMap { BaseTime(baseTimeData: $0) }
		}

		return baseTime
	}

	func setImageCache(fileName: String, forBaseTime baseTime: BaseTime) -> UIImage? {
		let image = NSBundle(forClass: self.dynamicType).pathForResource(fileName, ofType: "png").flatMap {
			NSData(contentsOfFile: $0).flatMap { UIImage(data: $0) }
		}

		if let image = image {
			for index in baseTime.range() {
				// set cache
				let imageContext = ImageContext(latitudeNumber: 0, longitudeNumber: 0, zoomLevel: .level6)
				let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: index)

				let url = Image.url(forImageContext: imageContext, baseTimeContext: baseTimeContext)!
				ImageManager.sharedManager.sharedImageCache.setObject(image, forKey: url.absoluteString)
			}
		}

		return image
	}

	func removeImageCache() {
		ImageManager.sharedManager.sharedImageCache.removeAllObjects()
		// wait seconds until disk cache flushed
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.5))
	}

	func waitForSeconds(seconds: NSTimeInterval) {
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: seconds))
	}
}
