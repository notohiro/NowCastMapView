//
//  ImageManager.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit
import AwesomeCache

final public class ImageManager {
	public static let sharedManager = ImageManager()

	public struct Notification {
		public static let name = "ImageManagerNotification"
		public static let object = "object"
		public static let error = "error"
	}

	let sharedImageCache = try! Cache<UIImage>(name: "ImageCache") // swiftlint:disable:this force_try
	var imagePool = SynchronizedDictionary<String, Image>()

	private init() { }

	public func isServiceAvailable(inMapRect mapRect: MKMapRect) -> Bool {
		// mapRect origin Coordinate
		let origin = MKCoordinateForMapPoint(mapRect.origin)
		// mapRect terminal Coordinate
		let  terminal = MKCoordinateForMapPoint(MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height))

		if origin.latitude > Constants.terminalLatitude &&
			terminal.latitude < Constants.originLatitude &&
			origin.longitude < Constants.terminalLongitude &&
			terminal.longitude > Constants.originLongitude {
				return true
		} else {
			return false
		}
	}

	public func isServiceAvailable(atCoordinate coordinate: CLLocationCoordinate2D) -> Bool {
		if coordinate.latitude > Constants.terminalLatitude &&
			coordinate.latitude < Constants.originLatitude &&
			coordinate.longitude < Constants.terminalLongitude &&
			coordinate.longitude > Constants.originLongitude {
				return true
		} else {
			return false
		}
	}

	public func images(inMapRect mapRect: MKMapRect, zoomScale: MKZoomScale, baseTimeContext: BaseTimeContext, priority: DownloadPriority) -> [Image] {
		var retArr = [Image]()
		if isServiceAvailable(inMapRect: mapRect) == false { return retArr }

		// mapRect origin Coordinate
		let originCoordinate = MKCoordinateForMapPoint(mapRect.origin)
		// mapRect terminal Coordinate
		let terminalPoint = MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height)
		let  terminalCoordinate = MKCoordinateForMapPoint(terminalPoint)


		// convert from MKZoomScale to NCZoomLevel
		let zoomLevel = ZoomLevel(zoomScale: zoomScale)

		// get image numbers
		let originNumbers = Image.numbers(forCoordinate: originCoordinate, zoomLevel: zoomLevel)
		let terminalNumbers = Image.numbers(forCoordinate: terminalCoordinate, zoomLevel: zoomLevel)

		// loop from origin to terminal
		for latNumber in originNumbers.latitudeNumber ... terminalNumbers.latitudeNumber {
			for lonNumber in originNumbers.longitudeNumber ... terminalNumbers.longitudeNumber {
				// get URL of image
				let imageContext = ImageContext(latitudeNumber: latNumber, longitudeNumber: lonNumber, zoomLevel: zoomLevel)
				guard let url = Image.url(forImageContext: imageContext, baseTimeContext: baseTimeContext) else { continue }

				if let image = imagePool.valueForKey(url.absoluteString) {
					if image.priority.rawValue < priority.rawValue { image.priority = priority }
					retArr.append(image)
				} else {
					if let image = Image(forImageContext: imageContext, baseTimeContext: baseTimeContext, priority: priority) {
						imagePool.setValue(image, forKey: url.absoluteString)
						retArr.append(image)
					}
				}
			}
		}

		return retArr
	}

	public func image(atCoordinate coordinate: CLLocationCoordinate2D, zoomScale: MKZoomScale,
	                               baseTimeContext: BaseTimeContext, priority: DownloadPriority) -> Image? {
		if isServiceAvailable(atCoordinate: coordinate) == false { return nil }

		let mapPoint = MKMapPointForCoordinate(coordinate)
		let mapRect = MKMapRect(origin: mapPoint, size: MKMapSize(width: 0, height: 0))

		return images(inMapRect: mapRect, zoomScale: zoomScale, baseTimeContext: baseTimeContext, priority: priority).first
	}

	public func cancelImageRequestsPriorityLessThan(priority: DownloadPriority) {
		imageSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
			for task in dataTasks {
				if task.priority < priority.rawValue {
					task.cancel()
					if let key = task.currentRequest?.URL?.absoluteString {
						self.imagePool.removeValueForKey(key)
					}
				}
			}
		}
	}

	public func removeExpiredCache() {
		sharedImageCache.removeExpiredObjects()
	}

	public func removeAllCache() {
		sharedImageCache.removeAllObjects()
	}

	public func flushMemoryCache() {
		imagePool.removeAll()
		imagePool = SynchronizedDictionary<String, Image>()
	}
}
