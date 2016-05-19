//
//  NowCastMapViewController.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/21/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public class NowCastMapViewController: UIViewController, MKMapViewDelegate, NowCastMapViewDataSource {
	@IBOutlet public weak var mapView: NowCastMapView! {
		didSet {
			mapView.dataSource = self
			mapView.delegate = self
		}
	}

	private var imageManager: NowCastImageManager = NowCastImageManager.sharedManager
	
	public var baseTime: NowCastBaseTime? {
		didSet { mapView.setNeedsDisplay() }
	}
	public var baseTimeIndex: Int = 0 {
		didSet { mapView.setNeedsDisplay() }
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(NowCastMapViewController.imageFetched(_:)), name: NowCastImageManager.Notification.name, object: nil)

		mapView = NowCastMapView(coder: aDecoder)
	}

	public override func viewDidLoad() {
		mapView.dataSource = self
	}

	public func prefetch(forMapRect mapRect: MKMapRect, zoomScale: MKZoomScale, baseTime: NowCastBaseTime, baseTimeIndexRange: Range<Int>) {
		if baseTimeIndexRange ~= 0 {
			imageManager.images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: baseTime, baseTimeIndex: 0, priority: kNowCastDownloadPriorityHigh)
		}

		let endIndex = baseTimeIndexRange.endIndex - 1
		if 1 <= endIndex {
			for index in 1 ... endIndex {
				imageManager.images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: baseTime, baseTimeIndex: index, priority: kNowCastDownloadPriorityPrefetchForward)
			}
		}

		if baseTimeIndexRange.startIndex < -1 {
			for index in baseTimeIndexRange.startIndex ... -1 {
				imageManager.images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: baseTime, baseTimeIndex: index, priority: kNowCastDownloadPriorityPrefetchBackward)
			}
		}
	}

	public func cancelPrefetch() {
		defaultSession.getTasksWithCompletionHandler() { dataTasks, uploadTasks, downloadTasks in
			for task in dataTasks {
				if task.priority <= kNowCastDownloadPriorityPrefetchForward { task.cancel() }
			}
		}
	}

// MARK: - MKMapViewDelegate
	public func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		let aMapView = mapView as! NowCastMapView
		return aMapView.renderer
	}

// MARK: - NowCastImageManagerNotification
	dynamic public func imageFetched(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let image = userInfo[NowCastImageManager.Notification.object] as? NowCastImage {
				if baseTime?.compare(image.baseTime) != .OrderedSame { return }
				if image.baseTimeIndex != baseTimeIndex { return }

				// check zoomScale
				// check region of MapView

				mapView?.setNeedsDisplay()
			}
		}
	}

// MARK: - NowCastMapViewDataSource
	public func isServiceAvailable(mapRect: MKMapRect) -> Bool {
		return imageManager.isServiceAvailable(inMapRect: mapRect)
	}

	public func nowCastImages(inMapRect mapRect: MKMapRect, forZoomScale zoomScale: MKZoomScale) -> [NowCastImage]? {
		if let aBaseTime = baseTime {
			let images = imageManager.images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: aBaseTime, baseTimeIndex: baseTimeIndex, priority: kNowCastDownloadPriorityHigh)
			return images
		}
		else { return nil }
	}
}
