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
A `Tile` structure represents a single tile file of
High-resolution Precipitation Nowcasts.
(http://www.jma.go.jp/en/highresorad/)

For performance, you should initialize `Tile` instance by using `TileModel`.
The `Tile` instances are cached by `TileModel`, and it handles duplicated requests.
*/
public struct Tile {

	// MARK: - Public Properties

	public let baseTime: BaseTime
	public let index: Int

	public let modifiers: Tile.Modifiers

	public let url: URL

	public var image: UIImage?

	public let deltas: Tile.Deltas

	public let coordinates: Coordinates
	public let mapRect: MKMapRect

	// MARK: - Internal Properties

	// MARK: - Functions

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

	/**
	Returns a Boolean value indicating whether the tile contains the given coordinate.
	Right(East) edge and Bottom(South) one of the `Tile` are not contained, because these edges are contained by next tiles,
	except if the `Tile` is on East or South service bound.

	- Parameter coordinate:	The coordinate to test for containment within this tile.

	- Returns: Whether the tile contains the given coordinate
	*/
	func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
		let origin = coordinates.origin
		let terminal = coordinates.terminal

		let north = origin.latitude >= coordinate.latitude
		let west = origin.longitude <= coordinate.longitude

		var south: Bool
		var east: Bool

		if modifiers.isOnServiceBound().south {
			south = coordinate.latitude >= terminal.latitude
		} else {
			south = coordinate.latitude > terminal.latitude
		}

		if modifiers.isOnServiceBound().east {
			east = coordinate.longitude <= terminal.longitude
		} else {
			east = coordinate.longitude < terminal.longitude
		}

		if north && west && south && east {
			return true
		} else {
			return false
		}
	}

	/**
	Returns a `RGBA255` value at the given coordinate.
	It could be nil if the coordinate don't be contained by the `Tile`.

	- Parameter coordinate:	The coordinate of the tile you want.

	- Returns: A `RGBA255` value at the given coordinate.
	*/
	public func rgba255(at coordinate: CLLocationCoordinate2D) -> RGBA255? {
		if contains(coordinate) == false { return nil }

		guard let point = point(at: coordinate) else { return nil }

		return image?.rgba255(at: point)
	}

	/**
	Returns a `CGPoint` value at the given coordinate.
	It could be nil if the coordinate don't be contained by the `Tile`.

	- Parameter coordinate:	The coordinate of the tile you want.

	- Returns: A `CGPoint` value at the given coordinate.
	*/
	func point(at coordinate: CLLocationCoordinate2D) -> CGPoint? {
		if contains(coordinate) == false { return nil }

		guard let image = self.image, let position = position(at: coordinate) else { return nil }

		let x = floor(image.size.width * CGFloat(position.longitudePosition))
		let y = floor(image.size.height * CGFloat(position.latitudePosition))

		return CGPoint.init(x: x, y: y)
	}

	/**
	Returns a normalized position at the given coordinate.
	It could be nil if the coordinate don't be contained by the `Tile`.
	The return value contains two dimensional position, and are between from 0.0 to 1.0.
	(0,0) describes top left, (1,1) is bottom right.
	(1,1) will never happen because bottom right edge don't be contained by the `Tile`.

	- Parameter coordinate:	The coordinate of the tile you want.

	- Returns: A normalized position at the given coordinate.
	*/
	func position(at coordinate: CLLocationCoordinate2D) -> (latitudePosition: Double, longitudePosition: Double)? {
		if contains(coordinate) == false { return nil }

		let latitudeNumberAsDouble = (coordinate.latitude - Constants.originLatitude) / -deltas.latitude
		let longitudeNumberAsDouble = (coordinate.longitude - Constants.originLongitude) / deltas.longitude

		let latitudePosition = latitudeNumberAsDouble - Double(modifiers.latitude)
		let longitudePosition = longitudeNumberAsDouble - Double(modifiers.longitude)

		return (latitudePosition, longitudePosition)
	}

	/**
	Returns a `CLLocationCoordinate2D` value at the given point.
	It could be nil if the point is outside of the image of `Tile`.

	- Parameter coordinate:	The point of the tile you want.

	- Returns: A `CLLocationCoordinate2D` value at the given point.
	*/
	func coordinate(at point: CGPoint) -> CLLocationCoordinate2D? {
		guard let image = self.image else { return nil }

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
