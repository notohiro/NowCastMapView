//
//  Image.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/26/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public struct ImageContext {
	// longitudeNumber_latitudeNumber.png
	public var latitudeNumber: Int
	public var longitudeNumber: Int
	public var zoomLevel: ZoomLevel

	public init(latitudeNumber: Int, longitudeNumber: Int, zoomLevel: ZoomLevel) {
		self.latitudeNumber = latitudeNumber
		self.longitudeNumber = longitudeNumber
		self.zoomLevel = zoomLevel
	}
}

public class Image: CustomStringConvertible {

// MARK: - Static Functions

	static func url(forImageContext imageContext: ImageContext, baseTimeContext: BaseTimeContext) -> NSURL? {
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

	static func numbers(forCoordinate coordinate: CLLocationCoordinate2D, zoomLevel: ZoomLevel) -> ImageContext {
		let deltas = Image.deltas(forZoomLevel: zoomLevel)

		// initialize mods
		let latDoubleNumber = (coordinate.latitude - Constants.originLatitude) / -deltas.latitudeDelta
		let latitudeNumber = Int(floor(latDoubleNumber))
		let lonDoubleNumber = (coordinate.longitude - Constants.originLongitude) / deltas.longitudeDelta
		let longitudeNumber = Int(floor(lonDoubleNumber))

		return ImageContext(latitudeNumber: latitudeNumber, longitudeNumber: longitudeNumber, zoomLevel: zoomLevel)
	}

	static func deltas(forZoomLevel zoomLevel: ZoomLevel) -> (latitudeDelta: Double, longitudeDelta: Double) {
		let latitudeDelta = Double(Constants.originLatitude - Constants.terminalLatitude) / Double(zoomLevel.rawValue)
		let longitudeDelta = Double(Constants.terminalLongitude - Constants.originLongitude) / Double(zoomLevel.rawValue)
		return (latitudeDelta, longitudeDelta)
	}

	static func coordinates(forImageContext context: ImageContext) -> (origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) {
		let deltas = Image.deltas(forZoomLevel: context.zoomLevel)
		let originLatitude = Constants.originLatitude - Double(context.latitudeNumber)*deltas.latitudeDelta
		let originLongitude = Constants.originLongitude + Double(context.longitudeNumber)*deltas.longitudeDelta
		let terminalLatitude = originLatitude - deltas.latitudeDelta
		let terminalLongitude = originLongitude + deltas.longitudeDelta

		let originCoordinate = CLLocationCoordinate2DMake(originLatitude, originLongitude)
		let terminalCoordinate = CLLocationCoordinate2DMake(terminalLatitude, terminalLongitude)

		return (originCoordinate, terminalCoordinate)
	}

	static func mapRect(forImageContext context: ImageContext) -> MKMapRect {
		let deltas = Image.deltas(forZoomLevel: context.zoomLevel)
		// make mapRect
		// top left coordinate of image
		let coordinates = Image.coordinates(forImageContext: context)
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
	public let imageContext: ImageContext
	public let baseTimeContext: BaseTimeContext
	public let url: NSURL
	public var imageData: UIImage?
	public var xRevertedImageData: UIImage?
	public var priority: DownloadPriority {
		didSet {
			guard let dataTask = self.dataTask else { return }
			dataTask.priority = priority.rawValue
		}
	}
	var dataTask: NSURLSessionDataTask?

// MARK: - Calculated Property
	public var description: String {
		return url.absoluteString
	}
	var deltas: (latitudeDelta: Double, longitudeDelta: Double) {
		return Image.deltas(forZoomLevel: imageContext.zoomLevel)
	}
	var rectCoordinates: (origin: CLLocationCoordinate2D, terminal: CLLocationCoordinate2D) {
		return Image.coordinates(forImageContext: imageContext)
	}
	public var mapRect: MKMapRect {
		return Image.mapRect(forImageContext: imageContext)
	}

// MARK: - Functions
	init?(forImageContext imageContext: ImageContext, baseTimeContext: BaseTimeContext, priority: DownloadPriority) {
		self.imageContext = imageContext
		self.baseTimeContext = baseTimeContext
		self.priority = priority

		guard let url = Image.url(forImageContext: imageContext, baseTimeContext: baseTimeContext) else { return nil }
		self.url = url

		// initialize mods
		if imageContext.latitudeNumber < 0 { return nil }
		if imageContext.latitudeNumber > imageContext.zoomLevel.rawValue - 1 { return nil }

		if imageContext.longitudeNumber < 0 { return nil }
		if imageContext.longitudeNumber > imageContext.zoomLevel.rawValue - 1 { return nil }

		let queue = NSOperationQueue()
		queue.addOperationWithBlock {
			// check cache exists
			if let imageData = ImageManager.sharedManager.sharedImageCache.objectForKey(url.absoluteString) {
				// if exists
				self.imageData = imageData
				self.xRevertedImageData = imageData.xReverted()
				self.notify(withError: nil)
			} else {
				// if not exists
				// to start download after all initialization finished
				self.dataTask = ImageManager.sharedManager.session.dataTaskWithURL(url) { [weak self] data, response, error in
					self?.downloadFinished(data, response: response, error: error)
				}
				self.dataTask?.priority = priority.rawValue
				self.dataTask?.resume()
			}
		}
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

		return imageData?.color(atPoint: point)
	}

	func point(atCoordinate coordinate: CLLocationCoordinate2D) -> CGPoint? {
		if contains(coordinate) == false { return nil }

		guard let imageData = self.imageData, position = position(atCoordinate: coordinate) else { return nil }

		let x = floor(imageData.size.width * CGFloat(position.longitudePosition))
		let y = floor(imageData.size.height * CGFloat(position.latitudePosition))

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
		guard let imageData = self.imageData else { return nil }

		// return nil if it's point is not on image
		if point.x < 0 || point.y < 0 || point.x >= imageData.size.width || point.y >= imageData.size.height {
			return nil
		}

		let latitudePosition = Double(point.y / imageData.size.height)
		let longitudePosition = Double(point.x / imageData.size.width)

		let latitudeDeltaPerPixel = deltas.latitudeDelta / Double(imageData.size.height)
		let longitudeDeltaPerPixel = deltas.longitudeDelta / Double(imageData.size.width)

		let latitude = Double(rectCoordinates.origin.latitude) - Double(deltas.latitudeDelta * latitudePosition) - (latitudeDeltaPerPixel / 2)
		let longitude = Double(rectCoordinates.origin.longitude) + Double(deltas.longitudeDelta * longitudePosition) + (longitudeDeltaPerPixel / 2)

		return CLLocationCoordinate2DMake(latitude, longitude)
	}

	public func downloadFinished(data: NSData?, response: NSURLResponse?, error: NSError?) {
		var notifyError: NSError?

		if let httpResponse = response as? NSHTTPURLResponse {
			if httpResponse.statusCode != 200 {
				objc_sync_enter(ImageManager.sharedManager)
				ImageManager.sharedManager.imagePool.removeValueForKey(url.absoluteString)
				objc_sync_exit(ImageManager.sharedManager)

				if error == nil {
					let httpError = NSError(domain: "NSURLErrorDomain", code: httpResponse.statusCode, userInfo: nil)
					notifyError = httpError
				} else {
					notifyError = error
				}
			}
		}

		let image =  data.flatMap { UIImage(data: $0) }
		if let imageData =  image {
			self.imageData = imageData
			self.xRevertedImageData = imageData.xReverted()
			let imageCache = ImageManager.sharedManager.sharedImageCache
			imageCache.setObject(imageData, forKey: url.absoluteString, expires: .Date(NSDate(timeIntervalSinceNow: 60*60*24*5)))
		}

		notify(withError: notifyError)
	}

	private func notify(withError error: NSError?) {
		var notifyObject = [NSObject : AnyObject]()
		notifyObject[ImageManager.Notification.object] = self
		notifyObject[ImageManager.Notification.error] = error

		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(ImageManager.Notification.name, object: nil, userInfo:notifyObject)
	}
}
