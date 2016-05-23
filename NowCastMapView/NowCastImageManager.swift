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

public enum NCZoomLevel: Int {
	static let MKZoomScaleAsNCZoomLevel4: CGFloat = 0.000488
	static let MKZoomScaleAsNCZoomLevel2: CGFloat = 0.000122

	case NCZoomLevel2 = 4
	case NCZoomLevel4 = 16
	case NCZoomLevel6 = 64

	init(zoomScale: MKZoomScale) {
		if zoomScale > NCZoomLevel.MKZoomScaleAsNCZoomLevel4 {
			self = .NCZoomLevel6
		}
		else if zoomScale > NCZoomLevel.MKZoomScaleAsNCZoomLevel2 {
			self = .NCZoomLevel4
		}
		else { self = .NCZoomLevel2 }
	}

	func toURLPrefix() -> String {
		switch self {
		case .NCZoomLevel2:
			return "zoom2"
		case .NCZoomLevel4:
			return "zoom4"
		case .NCZoomLevel6:
			return "zoom6"
		}
	}
}

internal class SynchronizedDictionary<S: Hashable, T> {
	private var _dictionary = [S : T]()
	private let accessQueue = dispatch_queue_create("SynchronizedDictionaryAccess", DISPATCH_QUEUE_SERIAL)

	internal func setValue(value: T, forKey key: S) {
		dispatch_async(accessQueue) {
			self._dictionary[key] = value
		}
	}

	internal func valueForKey(key: S) -> T? {
		var value: T?
		dispatch_sync(accessQueue) {
			value = self._dictionary[key]
		}
		return value
	}

	internal func removeValueForKey(key: S) {
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

	internal let sharedImageCache = try! Cache<UIImage>(name: "NowCastImageCache")
	internal var imagePool = SynchronizedDictionary<String, Weak<NowCastImage>>()
	internal var processingImages = SynchronizedDictionary<String, NowCastImage>()
	
	private init() { }

	public func isServiceAvailable(inMapRect mapRect: MKMapRect) -> Bool {
		// mapRect origin Coordinate
		let origin = MKCoordinateForMapPoint(mapRect.origin);
		// mapRect terminal Coordinate
		let  terminal = MKCoordinateForMapPoint(MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height));

		if origin.latitude > NowCastTerminalLatitude &&
			terminal.latitude < NowCastOriginLatitude &&
			origin.longitude < NowCastTerminalLongitude &&
			terminal.longitude > NowCastOriginLongitude {
				return true
		}
		else { return false }
	}

	public func isServiceAvailable(atCoordinate coordinate: CLLocationCoordinate2D) -> Bool {
		if coordinate.latitude > NowCastTerminalLatitude &&
			coordinate.latitude < NowCastOriginLatitude &&
			coordinate.longitude < NowCastTerminalLongitude &&
			coordinate.longitude > NowCastOriginLongitude {
				return true
		}
		else { return false }
	}

	public func images(forMapRect mapRect: MKMapRect, zoomScale: MKZoomScale, baseTime: NowCastBaseTime, baseTimeIndex: Int, priority: Float) -> [NowCastImage] {
		var retArr = [NowCastImage]()
		if isServiceAvailable(inMapRect: mapRect) == false { return retArr }

		// mapRect origin Coordinate
		let originCoordinate = MKCoordinateForMapPoint(mapRect.origin)
		// mapRect terminal Coordinate
		let terminalPoint = MKMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y + mapRect.size.height)
		let  terminalCoordinate = MKCoordinateForMapPoint(terminalPoint)


		// convert from MKZoomScale to NCZoomLevel
		let zoomLevel = NCZoomLevel(zoomScale: zoomScale)
		
		// get image numbers
		let originNumbers = NowCastImage.imageNumbers(forCoordinate: originCoordinate, zoomLevel: zoomLevel)
		let terminalNumbers = NowCastImage.imageNumbers(forCoordinate: terminalCoordinate, zoomLevel: zoomLevel)

		// loop from origin to terminal
		for latNumber in originNumbers.latitudeNumber ... terminalNumbers.latitudeNumber {
			for lonNumber in originNumbers.longitudeNumber ... terminalNumbers.longitudeNumber {
				// get URL of image
				if let aURL = NowCastImage.imageURL(forLatitudeNumber: latNumber, longitudeNumber: lonNumber, zoomLevel: zoomLevel, baseTime: baseTime, baseTimeIndex: baseTimeIndex) {

					objc_sync_enter(self)
					if let ncImage = imagePool.valueForKey(aURL.absoluteString)?.value() {
						if ncImage.priority < priority { ncImage.priority = priority }
						retArr.append(ncImage)
					}
					else {
						if let nowCastImage = NowCastImage(latitudeNumber: latNumber, longitudeNumber: lonNumber, zoomLevel: zoomLevel, baseTime: baseTime, baseTimeIndex: baseTimeIndex, priority: priority) {
							retArr.append(nowCastImage)
						}
					}
					objc_sync_exit(self)
				}
			}
		}
		return retArr
	}

	public func image(atCoordinate coordinate: CLLocationCoordinate2D, zoomScale: MKZoomScale, baseTime: NowCastBaseTime, baseTimeIndex: Int, priority: Float) -> NowCastImage? {
		if isServiceAvailable(atCoordinate: coordinate) == false { return nil }

		let mapPoint = MKMapPointForCoordinate(coordinate)
		let mapRect = MKMapRect(origin: mapPoint, size: MKMapSize(width: 0, height: 0))

		return images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: baseTime, baseTimeIndex: baseTimeIndex, priority: priority).first
	}

	public func removeExpiredCache() {
		sharedImageCache.removeExpiredObjects()
	}

	public func removeAllCache() {
		sharedImageCache.removeAllObjects()
	}
}