//
//  ViewController.swift
//  Example
//
//  Created by Hiroshi Noto on 1/26/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import UIKit
import NowCastMapView
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, NowCastOverlayRendererDataSource {

// MARK: - IBOutlets

	@IBOutlet weak var mapView: MKMapView!

// MARK: - NowCastMapViewDataSource

	var baseTime: NowCastBaseTime? {
		didSet { renderer.setNeedsDisplay() }
	}

	var baseTimeIndex: Int = 0 {
		didSet { renderer.setNeedsDisplay() }
	}

// MARK: - Other Variables

	var overlay = NowCastOverlay()
	var renderer: NowCastOverlayRenderer!
	let imageManager = NowCastImageManager.sharedManager

	var annotation: MKPointAnnotation? {
		didSet {
			if let baseTime = baseTime, annotation = annotation {
				let _ = NowCastRainLevels(baseTime: baseTime, coordinate: annotation.coordinate) { rainLevels, error in
					NSOperationQueue.mainQueue().addOperationWithBlock {
						if let baseTimeString = rainLevels.baseTime.baseTimeString(atIndex: 0), level = rainLevels.rainLevel(atBaseTimeIndex: 0)?.level {

							let message = baseTimeString + ": level = " + String(level)
							let alertController = UIAlertController(title: "Fetched NowCastRainLevels", message: message, preferredStyle: .Alert)

							let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
							alertController.addAction(defaultAction)

							self.presentViewController(alertController, animated: true, completion: nil)
						}
					}
				}
			}
		}
	}

// MARK: - Application Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

		// Initialize mapView
		mapView.delegate = self

		// Initialize Overlay and Renderer
		renderer = NowCastOverlayRenderer(overlay: overlay)
		renderer.dataSource = self
		mapView.addOverlay(overlay)

		// register notification
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(ViewController.baseTimeUpdated(_:)), name: NowCastBaseTimeManager.Notification.name, object: nil)
		nc.addObserver(self, selector: #selector(ViewController.imageFetched(_:)), name: NowCastImageManager.Notification.name, object: nil)

		// restore last baseTime
		baseTime = NowCastBaseTimeManager.sharedManager.lastSavedBaseTime
    }

// MARK: - IBAction

	@IBAction func handleLongPressGesture(sender: UILongPressGestureRecognizer) {
		if (sender.state == .Began) {
			// remove existing annotations
			mapView.removeAnnotations(mapView.annotations)

			// add annotation
			let touchedPoint = sender.locationInView(mapView)
			let touchCoordinate = mapView.convertPoint(touchedPoint, toCoordinateFromView: mapView)

			let anno = MKPointAnnotation()
			anno.coordinate = touchCoordinate
			annotation = anno
			mapView.addAnnotation(anno)
		}
	}

// MARK: - MKMapViewDelegate

	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		return renderer
	}

// MARK: - NowCastOverlayRendererDataSource

	func nowCastImages(inMapRect mapRect: MKMapRect, forZoomScale zoomScale: MKZoomScale) -> [NowCastImage]? {
		if let baseTime = self.baseTime {
			let images = imageManager.images(forMapRect: mapRect, zoomScale: zoomScale, baseTime: baseTime, baseTimeIndex: baseTimeIndex, priority: NowCastDownloadPriorityHigh)
			return images
		}
		else { return nil }
	}

// MARK: - UIGestureRecognizerDelegate

	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}

// MARK: - NowCastBaseTimeManager.Notification

    func baseTimeUpdated(notification: NSNotification) {
        if let userInfo = notification.userInfo {
			if let object = userInfo[NowCastBaseTimeManager.Notification.object] as? NowCastBaseTimeManagerNotificationObject {
				if object.fetchResult == .OrderedAscending {
					baseTime = object.baseTime
				}
			}
        }
    }

// MARK: - NowCastImageManagerNotification

	dynamic func imageFetched(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let image = userInfo[NowCastImageManager.Notification.object] as? NowCastImage {
				if baseTime?.compare(image.baseTime) != .OrderedSame { return }
				if image.baseTimeIndex != baseTimeIndex { return }

				// check region of MapView
				// issue #3

				renderer.setNeedsDisplay()
			}
		}
	}
}

