//
//  NowCastImageManager.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit
import AwesomeCache

class SynchronizedDictionary<S: Hashable, T> {
	private var _dictionary = [S : T]()
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

final public class NowCastImageManager {
	public static let sharedManager = NowCastImageManager()
	
	public struct Notification {
		public static let name = "NowCastImageManagerNotification"
		public static let object = "object"
		public static let error = "error"
	}

	let sharedImageCache = try! Cache<UIImage>(name: "NowCastImageCache")
	var imagePool = SynchronizedDictionary<String, Weak<NowCastImage>>()
	var processingImages = SynchronizedDictionary<String, NowCastImage>()
	
	private init() { }

	public func isServiceAvailable(inMapRect mapRect: MKMapRect) -> Bool {
		// mapRect origin Coordinate
		let origin = MKCoordinateForMapPoint(mapRect.origin);
		// mapRect terminal Coordinate
		let  terminal = MKCoordinateForMapPoint(MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height));

		if origin.latitude > Constants.terminalLatitude &&
			terminal.latitude < Constants.originLatitude &&
			origin.longitude < Constants.terminalLongitude &&
			terminal.longitude > Constants.originLongitude {
				return true
		}
		else { return false }
	}

	public func isServiceAvailable(atCoordinate coordinate: CLLocationCoordinate2D) -> Bool {
		if coordinate.latitude > Constants.terminalLatitude &&
			coordinate.latitude < Constants.originLatitude &&
			coordinate.longitude < Constants.terminalLongitude &&
			coordinate.longitude > Constants.originLongitude {
				return true
		}
		else { return false }
	}

	public func images(forMapRect mapRect: MKMapRect, zoomScale: MKZoomScale, baseTime: NowCastBaseTime, baseTimeIndex: Int, priority: NowCastDownloadPriority) -> [NowCastImage] {
		var retArr = [NowCastImage]()
		if isServiceAvailable(inMapRect: mapRect) == false { return retArr }

		// mapRect origin Coordinate
		let originCoordinate = MKCoordinateForMapPoint(mapRect.origin)
		// mapRect terminal Coordinate
		let terminalPoint = MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height)
		let  terminalCoordinate = MKCoordinateForMapPoint(terminalPoint)


		// convert from MKZoomScale to NCZoomLevel
		let zoomLevel = NowCastZoomLevel(zoomScale: zoomScale)
		
		// get image numbers
		let originNumbers = NowCastImage.numbers(forCoordinate: originCoordinate, zoomLevel: zoomLevel)
		let terminalNumbers = NowCastImage.numbers(forCoordinate: terminalCoordinate, zoomLevel: zoomLevel)

		// loop from origin to terminal
		for latNumber in originNumbers.latitudeNumber ... terminalNumbers.latitudeNumber {
			for lonNumber in originNumbers.longitudeNumber ... terminalNumbers.longitudeNumber {
				// get URL of image
				let imageContext = NowCastImageContext(latitudeNumber: latNumber, longitudeNumber: lonNumber, zoomLevel: zoomLevel)
				let baseTimeContext = NowCastBaseTimeContext(baseTime: baseTime, index: baseTimeIndex)
				if let aURL = NowCastImage.url(forImageContext: imageContext, baseTimeContext: baseTimeContext) {

					objc_sync_enter(self)
					if let ncImage = imagePool.valueForKey(aURL.absoluteString)?.value() {
						if ncImage.priority.rawValue < priority.rawValue { ncImage.priority = priority }
						retArr.append(ncImage)
					}
					else {
						if let nowCastImage = NowCastImage(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: priority) {
							retArr.append(nowCastImage)
						}
					}
					objc_sync_exit(self)
				}
			}
		}
		return retArr
	}

	public func image(atCoordinate coordinate: CLLocationCoordinate2D, zoomScale: MKZoomScale, baseTime: NowCastBaseTime, baseTimeIndex: Int, priority: NowCastDownloadPriority) -> NowCastImage? {
		if isServiceAvailable(atCoordinate: coordinate) == false { return nil }

		let mapPoint = MKMapPointForCoordinate(coordinate)
		let mapRect = MKMapRect(origin: mapPoint, size: MKMapSize(width: 0, height: 0))

		return images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: baseTime, baseTimeIndex: baseTimeIndex, priority: priority).first
	}

	public func cancelImageRequestsPriorityLessThan(priority: Float) {
		imageSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
			for task in dataTasks {
				if task.priority < priority { task.cancel() }
			}
		}
	}

	public func removeExpiredCache() {
		sharedImageCache.removeExpiredObjects()
	}

	public func removeAllCache() {
		sharedImageCache.removeAllObjects()
	}
}