//
//  OverlayRenderer.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

open class OverlayRenderer: MKOverlayRenderer {

	static let DefaultBackgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.6)

	open let baseTime: BaseTime
	open let index: Int
	open let tileModel: TileModel

	public var backgroundColor = OverlayRenderer.DefaultBackgroundColor
	public var lastRequestedZoomScale: MKZoomScale?

	public init(overlay: MKOverlay, baseTime: BaseTime, index: Int) {
		self.baseTime = baseTime
		self.index = index
		tileModel = TileModel(baseTime: baseTime)

		super.init(overlay: overlay)
		tileModel.delegate = self
	}

	deinit {
		print("OverlayRenderer.deinit")
		tileModel.cancel()
	}

	override open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
		lastRequestedZoomScale = zoomScale

		let coordinates = Coordinates(mapRect: mapRect)
		let request = TileModel.Request(index: index, scale: zoomScale, coordinates: coordinates)
		let tiles = tileModel.tiles(with: request)
		tileModel.resume()

		tiles.forEach { tile in
			if let image = tile.image {
				context.clear(rect(for: tile.mapRect))
				context.setAlpha(0.6)

				UIGraphicsPushContext(context)
				image.draw(in: rect(for: tile.mapRect))
				UIGraphicsPopContext()
			} else {
				var red: CGFloat = 0
				var green: CGFloat = 0
				var blue: CGFloat = 0
				var alpha: CGFloat = 0
				backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

				context.setFillColor(red: red, green: green, blue: blue, alpha: alpha)
				context.fill(rect(for: tile.mapRect))
			}
		}
	}
}

extension OverlayRenderer: TileModelDelegate {
	public func tileModel(_ model: TileModel, added tiles: Set<Tile>) {
		tiles.forEach {
			setNeedsDisplayIn($0.mapRect)
		}
	}

	public func tileModel(_ model: TileModel, failed tile: Tile) { }
}
