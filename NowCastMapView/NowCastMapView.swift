//
//  NowCastMapView.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public protocol NowCastMapViewDataSource: NSObjectProtocol {
	func nowCastImages(inMapRect mapRect: MKMapRect, forZoomScale zoomScale: MKZoomScale) -> [NowCastImage]?
	func isServiceAvailable(mapRect: MKMapRect) -> Bool
}

public class NowCastMapView: MKMapView {
	private var overlay = NowCastOverlay()
	public var renderer: NowCastOverlayRenderer
	public weak var dataSource: NowCastMapViewDataSource?
	public var currentZoomScale: MKZoomScale?

	required public init?(coder aDecoder: NSCoder) {
		renderer = NowCastOverlayRenderer(overlay: overlay)

		super.init(coder: aDecoder)

		addOverlay(overlay)
		renderer.mapView = self
	}

	public override init(frame: CGRect) {
		renderer = NowCastOverlayRenderer(overlay: overlay)

		super.init(frame: frame)

		addOverlay(overlay)
		renderer.mapView = self
	}

	override public func setNeedsDisplay() {
		super.setNeedsDisplay()
		renderer.setNeedsDisplay()
	}

	public func setUnDownloadedBackgroundColor(color: UIColor) {
		renderer.backgroundColor = color
	}
}
