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
	lazy open private(set) var tileCache: TileCache = TileCache(baseTime: self.baseTime, delegate: self)

	public var backgroundColor = OverlayRenderer.DefaultBackgroundColor
	public var imageAlpha: CGFloat = 0.6
	public var lastRequestedZoomScale: MKZoomScale?

	public init(overlay: MKOverlay, baseTime: BaseTime, index: Int) {
		self.baseTime = baseTime
		self.index = index

		super.init(overlay: overlay)
	}

	override open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
		lastRequestedZoomScale = zoomScale

		let request = TileModel.Request(range: index...index, scale: zoomScale, mapRect: mapRect)
		let tiles = tileCache.tiles(with: request)

		tiles.forEach { tile in
			if let image = tile.image {
				context.clear(rect(for: tile.mapRect))

				UIGraphicsPushContext(context)
				image.draw(in: rect(for: tile.mapRect), blendMode: .normal, alpha: imageAlpha)
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
	public func tileModel(_ model: TileModel, task: TileModel.Task, added tile: Tile) {
		setNeedsDisplayIn(tile.mapRect)
	}

	public func tileModel(_ model: TileModel, task: TileModel.Task, failed tile: Tile) { }
}
