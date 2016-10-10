//
//  Tile.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/26/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

/**
A Tile structure represents a single tile file of
High-resolution Precipitation Nowcasts.
(http://www.jma.go.jp/en/highresorad/)

A initializer immediately returns a instance that doesn't have tile data.
Observable(you can get by `asObservable`) publishes events when
a tile fetched from disk/Web or error occured.

For performance, you should initialized by using TileManager.
Tile instances are cached by TileManager, and it handles duplicated requests.
*/
public struct Tile {

	// MARK: - Public Properties
	public let baseTime: BaseTime
	public let index: Int
	public let modifiers: Tile.Modifiers

	/// The URL of instance.
	public let url: URL

	/// The tile data. This will be nil until `.asObeservable.onNext` or `.tileFetched == true`.
	public var image: UIImage?

	/// The coordinate deltas of instance.
	public let deltas: Tile.Deltas

	/// The origin and terminal coordinates of instance.
	public let coordinates: Coordinates

	/// The MapRect of instance.
	public let mapRect: MKMapRect


	var dataTask: URLSessionDataTask?

	// MARK: - Functions

	/**
	Initializes and returns the Tile instance.
	`.tileData` and `.xRevertedTileData` will be nil until `.tileFetched` becomes true.
	To cactch the events emitted by the instance, subscribe `.asObservable`.

	- Parameter image:				The image.
	- Parameter tileContext:		The tileContext.
	- Parameter baseTimeContext:	The baseTimeContext.
	- Parameter priority:			The priority of tile download task.
	*/
	init(image: UIImage?, baseTime: BaseTime, index: Int, modifiers: Tile.Modifiers, url: URL) {
		self.image = image
		self.baseTime = baseTime
		self.index = index
		self.modifiers = modifiers
		self.coordinates = Coordinates(modifiers: modifiers)
		self.url = url
		self.deltas = Tile.Deltas(zoomLevel: modifiers.zoomLevel)
		self.mapRect = MKMapRect(modifiers: modifiers)
	}

	func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
		let origin = coordinates.origin
		let terminal = coordinates.terminal

		// dont include right & bottom border
		if origin.latitude >= coordinate.latitude && coordinate.latitude > terminal.latitude &&
			origin.longitude <= coordinate.longitude && coordinate.longitude < terminal.longitude {
			return true
		} else {
			return false
		}
	}

	func rgba255(at coordinate: CLLocationCoordinate2D) -> RGBA255? {
		if contains(coordinate) == false { return nil }

		guard let point = point(at: coordinate) else { return nil }

		return image?.rgba255(at: point)
	}

	func point(at coordinate: CLLocationCoordinate2D) -> CGPoint? {
		if contains(coordinate) == false { return nil }

		guard let image = self.image, let position = position(at: coordinate) else { return nil }

		let x = floor(image.size.width * CGFloat(position.longitudePosition))
		let y = floor(image.size.height * CGFloat(position.latitudePosition))

		return CGPoint.init(x: x, y: y)
	}

	func position(at coordinate: CLLocationCoordinate2D) -> (latitudePosition: Double, longitudePosition: Double)? {
		if contains(coordinate) == false { return nil }

		let latitudeNumberAsDouble = (coordinate.latitude - Constants.originLatitude) / -deltas.latitude
		let longitudeNumberAsDouble = (coordinate.longitude - Constants.originLongitude) / deltas.longitude

		let latitudePosition = latitudeNumberAsDouble - Double(modifiers.latitude)
		let longitudePosition = longitudeNumberAsDouble - Double(modifiers.longitude)

		return (latitudePosition, longitudePosition)
	}

	func coordinate(at point: CGPoint) -> CLLocationCoordinate2D? {
		guard let image = self.image else { return nil }

		// return nil if it's point is not on tile
		if point.x < 0 || point.y < 0 || point.x >= image.size.width || point.y >= image.size.height {
			return nil
		}

		let latitudePosition = Double(point.y / image.size.height)
		let longitudePosition = Double(point.x / image.size.width)

		let latitudeDeltaPerPixel = deltas.latitude / Double(image.size.height)
		let longitudeDeltaPerPixel = deltas.longitude / Double(image.size.width)

		let latitude = Double(coordinates.origin.latitude) - Double(deltas.latitude * latitudePosition) - (latitudeDeltaPerPixel / 2)
		let longitude = Double(coordinates.origin.longitude) + Double(deltas.longitude * longitudePosition) + (longitudeDeltaPerPixel / 2)

		return CLLocationCoordinate2DMake(latitude, longitude)
	}
}

// MARK: - Hashable

extension Tile: Hashable {
	public var hashValue: Int {
		return url.hashValue
	}
}

// MARK: - Equatable

extension Tile: Equatable {
	public static func == (lhs: Tile, rhs: Tile) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

// MARK: - CustomStringConvertible

extension Tile: CustomStringConvertible {
	public var description: String {
		return url.absoluteString
	}
}

// MARK: - CustomDebugStringConvertible

extension Tile: CustomDebugStringConvertible {
	public var debugDescription: String {
		var output: [String] = []

		output.append("[url]: \(url)")
		output.append(image != nil ? "[image]: not nil" : "[image]: nil")

		return output.joined(separator: "\n")
	}
}
