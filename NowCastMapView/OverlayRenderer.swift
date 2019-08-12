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
    public static let DefaultBackgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6)

    public let baseTime: BaseTime
    public let index: Int
    open private(set) lazy var tileCache = TileCache(baseTime: self.baseTime, delegate: self)

    public var backgroundColor = OverlayRenderer.DefaultBackgroundColor
    public var imageAlpha: CGFloat = 0.6
    public var lastDrawZoomScale: MKZoomScale?

    public init(overlay: MKOverlay, baseTime: BaseTime, index: Int) {
	    self.baseTime = baseTime
	    self.index = index

	    super.init(overlay: overlay)
    }

    deinit { }

    override open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
	    lastDrawZoomScale = zoomScale

	    let intersectedMapRect = mapRect.intersection(TileModel.serviceAreaMapRect)
	    let request = TileModel.Request(range: index...index, scale: zoomScale, mapRect: intersectedMapRect)

	    var red: CGFloat = 0
	    var green: CGFloat = 0
	    var blue: CGFloat = 0
	    var alpha: CGFloat = 0
	    backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

	    context.setFillColor(red: red, green: green, blue: blue, alpha: alpha)
	    context.fill(rect(for: intersectedMapRect))

	    guard let tiles = try? tileCache.tiles(with: request) else { return }

	    tiles.forEach { tile in
    	    if let image = tile.image {
	    	    context.clear(rect(for: tile.mapRect))

	    	    UIGraphicsPushContext(context)
	    	    image.draw(in: rect(for: tile.mapRect), blendMode: .normal, alpha: imageAlpha)
	    	    UIGraphicsPopContext()
    	    }
	    }
    }
}

extension OverlayRenderer: TileModelDelegate {
    public func tileModel(_ model: TileModel, task: TileModel.Task, added tile: Tile) {
	    setNeedsDisplay(tile.mapRect)
    }

    public func tileModel(_ model: TileModel, task: TileModel.Task, failed url: URL, error: Error) { }
}
