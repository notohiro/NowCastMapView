//
//  NowCastImage.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/26/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public struct NowCastImageContext {
	// longitudeNumber_latitudeNumber.png
	public var latitudeNumber: Int
	public var longitudeNumber: Int
	public var zoomLevel: NowCastZoomLevel
}

public class NowCastImage: CustomStringConvertible {

// MARK: - Static Functions

	static func url(forImageContext imageContext: NowCastImageContext, baseTimeContext: NowCastBaseTimeContext) -> NSURL? {
		var forecastTimeString: String
		var viewTimeString: String

		// will view past data
		if baseTimeContext.index < 0 {
			guard let aForecastTimeString = baseTimeContext.baseTime.baseTimeString(atIndex: baseTimeContext.index) else { return nil }

			forecastTimeString = aForecastTimeString
			viewTimeString = forecastTimeString
		// will view future datad
		} else {
			guard let aForecastTimeString = baseTimeContext.baseTime.baseTimeString(atIndex: 0) else { return nil }
			guard let aViewTimeString = baseTimeContext.baseTime.baseTimeString(atIndex: baseTimeContext.index) else { return nil }

			forecastTimeString = aForecastTimeString
			viewTimeString = aViewTimeString
		}

		let retStr = String(format: "%@%@%@%@%@%@%@%ld%@%ld%@",
			"http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/",
			forecastTimeString, "/", viewTimeString, "/", imageContext.zoomLevel.toURLPrefix(), "/",
			imageContext.longitudeNumber, "_", imageContext.latitudeNumber, ".png")

		return NSURL(string: retStr)
	}

	static func numbers(forCoordinate coordinate: CLLocationCoordinate2D, zoomLevel: NowCastZoomLevel) -> NowCastImageContext {
		let deltas = NowCastImage.deltas(forZoomLevel: zoomLevel)

		// initialize mods
		let latDoubleNumber = (coordinate.latitude - Constants.originLatitude) / -deltas.latitudeDelta
		let latitudeNumber = Int(floor(latDoubleNumber))
		let lonDoubleNumber = (coordinate.longitude - Constants.originLongitude) / deltas.longitudeDelta
		let longitudeNumber = Int(floor(lonDoubleNumber))

		return NowCastImageContext(latitudeNumber: latitudeNumber, longitudeNumber: longitudeNumber, zoomLevel: zoomLevel)
	}

	static func deltas(forZoomLevel zoomLevel: NowCastZoomLevel) -> (latitudeDelta: Double, longitudeDelta: Double) {
		let latitudeDelta = Double(Constants.originLatitude - Constants.terminalLatitude) / Double(zoomLevel.rawValue)
		let longitudeDelta = Double(Constants.terminalLongitude - Constants.originLongitude) / Double(zoomLevel.rawValue)
		return (latitudeDelta, longitudeDelta)
	}

	static func coordinates(forImageContext context: NowCastImageContext) -> (origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) {
		let deltas = NowCastImage.deltas(forZoomLevel: context.zoomLevel)
		let originLatitude = Constants.originLatitude - Double(context.latitudeNumber)*deltas.latitudeDelta
		let originLongitude = Constants.originLongitude + Double(context.longitudeNumber)*deltas.longitudeDelta
		let terminalLatitude = originLatitude - deltas.latitudeDelta
		let terminalLongitude = originLongitude + deltas.longitudeDelta

		let originCoordinate = CLLocationCoordinate2DMake(originLatitude, originLongitude)
		let terminalCoordinate = CLLocationCoordinate2DMake(terminalLatitude, terminalLongitude)

		return (originCoordinate, terminalCoordinate)
	}

	static func mapRect(forImageContext context: NowCastImageContext) -> MKMapRect {
		let deltas = NowCastImage.deltas(forZoomLevel: context.zoomLevel)
		// make mapRect
		// top left coordinate of image
		let coordinates = NowCastImage.coordinates(forImageContext: context)
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
	public let imageContext: NowCastImageContext
	public let baseTimeContext: NowCastBaseTimeContext
	public let url: NSURL
	public var image: UIImage?
	public var priority: NowCastDownloadPriority {
		didSet {
			if let dataTask = self.dataTask { dataTask.priority = priority.rawValue }
		}
	}
	var dataTask: NSURLSessionDataTask?

// MARK: - Calculated Property
	public var description: String {
		return url.absoluteString
	}
	var deltas: (latitudeDelta: Double, longitudeDelta: Double) {
		return NowCastImage.deltas(forZoomLevel: imageContext.zoomLevel)
	}
	var rectCoordinates: (origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) {
		return NowCastImage.coordinates(forImageContext: imageContext)
	}
	var mapRect: MKMapRect {
		return NowCastImage.mapRect(forImageContext: imageContext)
	}

// MARK: - Functions
	init?(forImageContext imageContext: NowCastImageContext, baseTimeContext: NowCastBaseTimeContext, priority: NowCastDownloadPriority) {
		self.imageContext = imageContext
		self.baseTimeContext = baseTimeContext
		self.priority = priority

		guard let url = NowCastImage.url(forImageContext: imageContext, baseTimeContext: baseTimeContext) else { return nil }
		self.url = url

		// check cache exists
		var needsDownload = false
		if let image = NowCastImageManager.sharedManager.sharedImageCache.objectForKey(url.absoluteString) {
			// if exists
			self.image = image
		} else {
			// if not exists
			// to start download after all initialization finished
			needsDownload = true
		}

		// initialize mods
		if imageContext.latitudeNumber < 0 { return nil }
		if imageContext.latitudeNumber > imageContext.zoomLevel.rawValue - 1 { return nil }

		if imageContext.longitudeNumber < 0 { return nil }
		if imageContext.longitudeNumber > imageContext.zoomLevel.rawValue - 1 { return nil }

		NowCastImageManager.sharedManager.imagePool.setValue(Weak(value: self), forKey: url.absoluteString)
		NowCastImageManager.sharedManager.processingImages.setValue(self, forKey: url.absoluteString)
		if needsDownload { downloadImage() }
	}

	deinit {
		NowCastImageManager.sharedManager.imagePool.removeValueForKey(url.absoluteString)
	}

	func contains(coordinate: CLLocationCoordinate2D) -> Bool {
		let origin = rectCoordinates.origin
		let terminal = rectCoordinates.terminal

		// dont include right & bottom border
		if origin.latitude >= coordinate.latitude && coordinate.latitude > terminal.latitude &&
			origin.longitude <= coordinate.longitude && coordinate.longitude < terminal.longitude {
			return true
		} else {
			return false
		}
	}

	func color(atCoordinate coordinate: CLLocationCoordinate2D) -> RGBA255? {
		if contains(coordinate) == false { return nil }

		guard let point = point(atCoordinate: coordinate) else { return nil }

		return image?.color(atPoint: point)
	}

	func point(atCoordinate coordinate: CLLocationCoordinate2D) -> CGPoint? {
		if contains(coordinate) == false { return nil }

		guard let image = self.image, position = position(atCoordinate: coordinate) else { return nil }

		let x = floor(image.size.width * CGFloat(position.longitudePosition))
		let y = floor(image.size.height * CGFloat(position.latitudePosition))

		return CGPoint.init(x: x, y: y)
	}

	func position(atCoordinate coordinate: CLLocationCoordinate2D) -> (latitudePosition: Double, longitudePosition: Double)? {
		if contains(coordinate) == false { return nil }

		let latitudeNumberAsDouble = (coordinate.latitude - Constants.originLatitude) / -deltas.latitudeDelta
		let longitudeNumberAsDouble = (coordinate.longitude - Constants.originLongitude) / deltas.longitudeDelta

		let latitudePosition = latitudeNumberAsDouble - Double(imageContext.latitudeNumber)
		let longitudePosition = longitudeNumberAsDouble - Double(imageContext.longitudeNumber)

		return (latitudePosition, longitudePosition)
	}

	func coordinate(atPoint point: CGPoint) -> CLLocationCoordinate2D? {
		guard let image = self.image else { return nil }

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

	private func downloadImage() {
		dataTask = imageSession.dataTaskWithURL(url) { [unowned self] data, response, error in
			self.downloadFinished(data, response: response, error: error)
		}
		dataTask?.priority = priority.rawValue
		dataTask?.resume()
	}

	public func downloadFinished(data: NSData?, response: NSURLResponse?, error: NSError?) {
		NowCastImageManager.sharedManager.processingImages.removeValueForKey(url.absoluteString)

		var notifyObject = [NSObject : AnyObject]()
		notifyObject[NowCastImageManager.Notification.object] = self
		notifyObject[NowCastImageManager.Notification.error] = error

		if let httpResponse = response as? NSHTTPURLResponse {
			if httpResponse.statusCode != 200 {
				if error == nil {
					let httpError = NSError(domain: "NSURLErrorDomain", code: httpResponse.statusCode, userInfo: nil)
					notifyObject[NowCastImageManager.Notification.error] = httpError
				}
			}
		}

		let image =  data.flatMap { UIImage(data: $0) }
		if let aImage =  image {
			self.image = aImage
			let imageCache = NowCastImageManager.sharedManager.sharedImageCache
			imageCache.setObject(aImage, forKey: url.absoluteString, expires: .Date(NSDate(timeIntervalSinceNow: 60*60*24*5)))
		}

		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(NowCastImageManager.Notification.name, object: nil, userInfo:notifyObject)
	}
}
