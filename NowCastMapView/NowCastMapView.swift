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
	var baseTime: NowCastBaseTime? { get }
	var baseTimeIndex: Int { get }
}

public class NowCastMapView: MKMapView, MKMapViewDelegate {
	private var imageManager: NowCastImageManager = NowCastImageManager.sharedManager
	private var overlay = NowCastOverlay()
	public var renderer: NowCastOverlayRenderer
	public weak var dataSource: NowCastMapViewDataSource?
	public var currentZoomScale: MKZoomScale?

	required public init?(coder aDecoder: NSCoder) {
		renderer = NowCastOverlayRenderer(overlay: overlay)
		super.init(coder: aDecoder)
		setup()
	}

	public override init(frame: CGRect) {
		renderer = NowCastOverlayRenderer(overlay: overlay)
		super.init(frame: frame)
		setup()
	}

	private func setup() {
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(NowCastMapView.imageFetched(_:)), name: NowCastImageManager.Notification.name, object: nil)
		addOverlay(overlay)
		renderer.mapView = self
		delegate = self
	}

	override public func setNeedsDisplay() {
		super.setNeedsDisplay()
		renderer.setNeedsDisplay()
	}

	public func setUnDownloadedBackgroundColor(color: UIColor) {
		renderer.backgroundColor = color
	}

	public func nowCastImages(inMapRect mapRect: MKMapRect, forZoomScale zoomScale: MKZoomScale) -> [NowCastImage]? {
		if let baseTime = dataSource?.baseTime, baseTimeIndex = dataSource?.baseTimeIndex {
			let images = imageManager.images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: baseTime, baseTimeIndex: baseTimeIndex, priority: kNowCastDownloadPriorityHigh)
			return images
		}
		else { return nil }
	}

// MARK: - MKMapViewDelegate

	public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		return renderer
	}

// MARK: - NowCastImageManagerNotification

	dynamic public func imageFetched(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let image = userInfo[NowCastImageManager.Notification.object] as? NowCastImage {
				if dataSource?.baseTime?.compare(image.baseTime) != .OrderedSame { return }
				if image.baseTimeIndex != dataSource?.baseTimeIndex { return }

				// check region of MapView
				// issue #3

				setNeedsDisplay()
			}
		}
	}
}
