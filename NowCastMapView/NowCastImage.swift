//
//  NowCastImage.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/26/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public class NowCastImage: CustomStringConvertible {
// MARK: - Static Functions
	internal static func imageURL(forLatitudeNumber latitudeNumber: Int, longitudeNumber: Int, zoomLevel: NCZoomLevel, baseTime: NowCastBaseTime, baseTimeIndex: Int) -> NSURL? {
		var forecastTimeString: String
		var viewTimeString: String

		// will view past data
		if baseTimeIndex < 0 {
			if let aForecastTimeString = baseTime.baseTimeString(atIndex: baseTimeIndex) {
				forecastTimeString = aForecastTimeString
				viewTimeString = forecastTimeString
			}
			else { return nil }
		}
			// will view future data
		else {
			if let aForecastTimeString = baseTime.baseTimeString(atIndex: 0) {
				forecastTimeString = aForecastTimeString
			}
			else { return nil }
			if let aViewTimeString = baseTime.baseTimeString(atIndex: baseTimeIndex) {
				viewTimeString = aViewTimeString
			}
			else { return nil }
		}

		let retStr = String(format: "%@%@%@%@%@%@%@%ld%@%ld%@",
			"http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/",
			forecastTimeString, "/", viewTimeString, "/", zoomLevel.toURLPrefix(), "/",
			longitudeNumber, "_", latitudeNumber, ".png")

		return NSURL(string: retStr)
	}

	internal static func imageNumbers(forCoordinate coordinate: CLLocationCoordinate2D, zoomLevel: NCZoomLevel) -> (latitudeNumber: Int, longitudeNumber: Int) {
		let deltas = NowCastImage.deltas(forZoomLevel: zoomLevel)

		// initialize mods
		let latDoubleNumber = (coordinate.latitude - kNowCastOriginLatitude) / -deltas.latitudeDelta
		let latitudeNumber = Int(floor(latDoubleNumber))
		let lonDoubleNumber = (coordinate.longitude - kNowCastOriginLongitude) / deltas.longitudeDelta
		let longitudeNumber = Int(floor(lonDoubleNumber))

		return (latitudeNumber, longitudeNumber)
	}

	internal static func deltas(forZoomLevel zoomLevel: NCZoomLevel) -> (latitudeDelta: Double, longitudeDelta: Double) {
		let latitudeDelta = Double(kNowCastOriginLatitude - kNowCastTerminalLatitude) / Double(zoomLevel.rawValue)
		let longitudeDelta = Double(kNowCastTerminalLongitude - kNowCastOriginLongitude) / Double(zoomLevel.rawValue)
		return (latitudeDelta, longitudeDelta)
	}

	internal static func coordinates(forlatitudeNumber latitudeNumber: Int, longitudeNumber: Int, zoomLevel: NCZoomLevel) -> (origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) {
		let deltas = NowCastImage.deltas(forZoomLevel: zoomLevel)
		let originLatitude = kNowCastOriginLatitude - Double(latitudeNumber)*deltas.latitudeDelta
		let originLongitude = kNowCastOriginLongitude + Double(longitudeNumber)*deltas.longitudeDelta
		let terminalLatitude = originLatitude - deltas.latitudeDelta
		let terminalLongitude = originLongitude + deltas.longitudeDelta

		let originCoordinate = CLLocationCoordinate2DMake(originLatitude, originLongitude)
		let terminalCoordinate = CLLocationCoordinate2DMake(terminalLatitude, terminalLongitude)

		return (originCoordinate, terminalCoordinate)
	}

	internal static func mapRect(forlatitudeNumber latitudeNumber: Int, longitudeNumber: Int, zoomLevel: NCZoomLevel) -> MKMapRect {
		let deltas = NowCastImage.deltas(forZoomLevel: zoomLevel)
		// make mapRect
		// top left coordinate of image
		let coordinates = NowCastImage.coordinates(forlatitudeNumber: latitudeNumber, longitudeNumber: longitudeNumber, zoomLevel: zoomLevel)
		let originLatitude = coordinates.origin.latitude
		let originLongitude = coordinates.origin.longitude

		// MKMapPoint, MKMapSize of origin, terminal
		let origin = MKMapPointForCoordinate(CLLocationCoordinate2DMake(originLatitude, originLongitude))
		let terminal = MKMapPointForCoordinate(CLLocationCoordinate2DMake(originLatitude - deltas.latitudeDelta, originLongitude + deltas.longitudeDelta))
		let size = MKMapSizeMake(terminal.x - origin.x, terminal.y - origin.y)

		// MKMapRect
		return MKMapRectMake(origin.x, origin.y, size.width, size.height)
	}

// MARK: - Variables
	public let latitudeNumber: Int, longitudeNumber: Int // longitudeNumber_latitudeNumber.png
	public let zoomLevel: NCZoomLevel
	public var image: UIImage?
	public let baseTime: NowCastBaseTime, baseTimeIndex: Int
	public let imageURL: NSURL
	public var priority: Float
//	private var observer: NSObjectProtocol?

// MARK: - Calculated Property
	public var description: String {
		return imageURL.absoluteString
	}
	internal var deltas: (latitudeDelta: Double, longitudeDelta: Double) {
		return NowCastImage.deltas(forZoomLevel: zoomLevel)
	}
	internal var rectCoordinates: (origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) {
		return NowCastImage.coordinates(
			forlatitudeNumber: latitudeNumber, longitudeNumber: longitudeNumber, zoomLevel: zoomLevel)
	}
	internal var mapRect: MKMapRect {
		return NowCastImage.mapRect(
			forlatitudeNumber: latitudeNumber, longitudeNumber: longitudeNumber, zoomLevel: zoomLevel)
	}

// MARK: - Functions
	internal init?(latitudeNumber: Int, longitudeNumber: Int, zoomLevel: NCZoomLevel, baseTime: NowCastBaseTime, baseTimeIndex: Int, priority: Float) {
		self.zoomLevel = zoomLevel
		self.baseTime = baseTime
		self.baseTimeIndex = baseTimeIndex
		self.latitudeNumber = latitudeNumber
		self.longitudeNumber = longitudeNumber
		self.priority = priority

		if let aURL = NowCastImage.imageURL(forLatitudeNumber: latitudeNumber, longitudeNumber: longitudeNumber, zoomLevel: zoomLevel, baseTime: baseTime, baseTimeIndex: baseTimeIndex) {
			self.imageURL = aURL
		}
		else {
			self.imageURL = NSURL()
			self.image = UIImage()
			return nil
		}

		// check cache exists
		var needsDownload = false
		if let image = NowCastImageManager.sharedManager.sharedImageCache.objectForKey(imageURL.absoluteString) {
			// if exists
			self.image = image
		}
		else {
			// if not exists
			// to start download after all initialization finished
			needsDownload = true
		}

		// initialize mods
		if latitudeNumber < 0 { return nil }
		else if latitudeNumber > zoomLevel.rawValue - 1 { return nil }

		if longitudeNumber < 0 { return nil }
		else if longitudeNumber > zoomLevel.rawValue - 1 { return nil }

		NowCastImageManager.sharedManager.imagePool.setValue(Weak(value: self), forKey: imageURL.absoluteString)
		NowCastImageManager.sharedManager.processingImages.setValue(self, forKey: imageURL.absoluteString)
		if needsDownload { downloadImage() }
	}

	deinit {
		NowCastImageManager.sharedManager.imagePool.removeValueForKey(imageURL.absoluteString)
	}

	internal func isOnImage(forCoordinate coordinate: CLLocationCoordinate2D) -> Bool {
		let origin = rectCoordinates.origin
		let terminal = rectCoordinates.terminal

		// dont include right & bottom border
		if origin.latitude >= coordinate.latitude && coordinate.latitude > terminal.latitude &&
			origin.longitude <= coordinate.longitude && coordinate.longitude < terminal.longitude { return true }
		else { return false }
	}

	internal func color(atCoordinate coordinate: CLLocationCoordinate2D) -> RGBA255? {
		if isOnImage(forCoordinate: coordinate) == false { return nil }

		if let point = point(atCoordinate: coordinate) {
			return image?.color(atPoint: point)
		}
		else { return nil }
	}

	internal func point(atCoordinate coordinate: CLLocationCoordinate2D) -> CGPoint? {
		if isOnImage(forCoordinate: coordinate) == false { return nil }

		if let image = self.image, position = position(atCoordinate: coordinate) {
			let x = floor(image.size.width * CGFloat(position.longitudePosition))
			let y = floor(image.size.height * CGFloat(position.latitudePosition))

			return CGPointMake(x, y)
		}
		else { return nil }
	}

	internal func position(atCoordinate coordinate: CLLocationCoordinate2D) -> (latitudePosition: Double, longitudePosition: Double)? {
		if isOnImage(forCoordinate: coordinate) == false { return nil }

		let latitudeNumberAsDouble = (coordinate.latitude - kNowCastOriginLatitude) / -deltas.latitudeDelta
		let longitudeNumberAsDouble = (coordinate.longitude - kNowCastOriginLongitude) / deltas.longitudeDelta

		let latitudePosition = latitudeNumberAsDouble - Double(latitudeNumber)
		let longitudePosition = longitudeNumberAsDouble - Double(longitudeNumber)

		return (latitudePosition, longitudePosition)
	}

	internal func coordinate(atPoint point: CGPoint) -> CLLocationCoordinate2D? {
		if let image = self.image {
			// return nil if it's point is not on image
			if point.x < 0 || point.y < 0 || point.x >= image.size.width || point.y >= image.size.height {
				return nil
			}

			let latitudePosition = Double(point.y / image.size.height)
			let longitudePosition = Double(point.x / image.size.width)

			let latitudeDeltaPerPixel = deltas.latitudeDelta / Double(image.size.height)
			let longitudeDeltaPerPixel = deltas.longitudeDelta / Double(image.size.width)

			let latitude = Double(rectCoordinates.origin.latitude) - Double(deltas.latitudeDelta * latitudePosition) - (latitudeDeltaPerPixel / 2)
			let longitude = Double(rectCoordinates.origin.longitude) + Double(deltas.longitudeDelta * longitudePosition) + (longitudeDeltaPerPixel / 2)

			return CLLocationCoordinate2DMake(latitude, longitude)
		}
		else { return nil }
	}

	private func downloadImage() {
		let task = defaultSession.dataTaskWithURL(imageURL) { [unowned self] data, response, error in
			self.downloadFinished(data, response: response, error: error)
		}
		task.priority = priority
		task.resume()
	}

	public func downloadFinished(data: NSData?, response: NSURLResponse?, error: NSError?) {
		NowCastImageManager.sharedManager.processingImages.removeValueForKey(imageURL.absoluteString)

		var notifyObject = [NSObject : AnyObject]()
		notifyObject[NowCastImageManager.Notification.object] = self
		notifyObject[NowCastImageManager.Notification.error] = error

		if let httpResponse = response as? NSHTTPURLResponse {
			if httpResponse.statusCode != 200 {
				let httpError = NSError(domain: "NSURLErrorDomain", code: httpResponse.statusCode, userInfo: nil)
				if error == nil { notifyObject[NowCastImageManager.Notification.error] = httpError }
			}
		}

		let image =  data.flatMap { UIImage(data: $0) }
		if let aImage =  image {
			self.image = aImage
			let imageCache = NowCastImageManager.sharedManager.sharedImageCache
			imageCache.setObject(aImage, forKey: imageURL.absoluteString, expires: .Date(NSDate(timeIntervalSinceNow: 60*60*24*5)))
		}

		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(NowCastImageManager.Notification.name, object: nil, userInfo:notifyObject)
	}
}
