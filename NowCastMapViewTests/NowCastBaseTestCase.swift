//
//  NowCastBaseTestCase.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 5/14/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import XCTest

class NowCastBaseTestCase: XCTestCase {
	let SecondsForTimeout = 3.0

	func getBaseTimeFrom(fileName: String) -> NowCastBaseTime? {
		let baseTime = NSBundle(forClass: self.dynamicType).pathForResource(fileName, ofType: "xml").flatMap {
			NSData(contentsOfFile: $0).flatMap { NowCastBaseTime(baseTimeData: $0) }
		}

		return baseTime
	}

	func setImageCache(fileName: String, forBaseTime baseTime: NowCastBaseTime) -> UIImage? {
		let image = NSBundle(forClass: self.dynamicType).pathForResource(fileName, ofType: "png").flatMap {
			NSData(contentsOfFile: $0).flatMap { UIImage(data: $0) }
		}

		if let image = image {
			for index in baseTime.range() {
				// set cache
				let URL = NowCastImage.imageURL(forLatitudeNumber: 0, longitudeNumber: 0, zoomLevel: .NCZoomLevel6, baseTime: baseTime, baseTimeIndex: index)!
				NowCastImageManager.sharedManager.sharedImageCache.setObject(image, forKey: URL.absoluteString)
			}
		}

		return image
	}

	func removeImageCache() {
		NowCastImageManager.sharedManager.sharedImageCache.removeAllObjects()
		// wait 2 seconds until disk cache flusheds
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.5))
	}

	func waitForSeconds(seconds: NSTimeInterval) {
		NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: seconds))
	}
}