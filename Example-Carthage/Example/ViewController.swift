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

class ViewController: UIViewController, MKMapViewDelegate, OverlayRendererDataSource {

	// MARK: - IBOutlets

	@IBOutlet weak var mapView: MKMapView!

	// MARK: - NowCastMapViewDataSource

	var baseTime: BaseTime? {
		didSet { renderer.setNeedsDisplay() }
	}

	var baseTimeIndex: Int = 0 {
		didSet { renderer.setNeedsDisplay() }
	}

	// MARK: - Other Variables

	var overlay = Overlay()
	var renderer: OverlayRenderer!
	let imageManager = ImageManager.sharedManager

	var annotation: MKPointAnnotation? {
		didSet {
			if let baseTime = baseTime, annotation = annotation {
				let _ = RainLevels(baseTime: baseTime, coordinate: annotation.coordinate) { rainLevels, error in
					NSOperationQueue.mainQueue().addOperationWithBlock {
						if let baseTimeString = rainLevels.baseTime.baseTimeString(atIndex: 0), level = rainLevels.rainLevel(atBaseTimeIndex: 0)?.level {

							let message = baseTimeString + ": level = " + String(level)
							let alertController = UIAlertController(title: "Fetched RainLevels", message: message, preferredStyle: .Alert)

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
		renderer = OverlayRenderer(overlay: overlay)
		renderer.dataSource = self
		mapView.addOverlay(overlay)

		// register notification
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(ViewController.baseTimeUpdated(_:)), name: BaseTimeManager.Notification.name, object: nil)
		nc.addObserver(self, selector: #selector(ViewController.imageFetched(_:)), name: ImageManager.Notification.name, object: nil)

		// restore last baseTime
		baseTime = BaseTimeManager.sharedManager.lastSavedBaseTime
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

	// MARK: - OverlayRendererDataSource

	func images(inMapRect mapRect: MKMapRect, forZoomScale zoomScale: MKZoomScale) -> [Image]? {
		if let baseTime = self.baseTime {
			let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: baseTimeIndex)
			return imageManager.images(inMapRect: mapRect, zoomScale: zoomScale, baseTimeContext: baseTimeContext, priority: .High)
		}
		else { return nil }
	}

	// MARK: - UIGestureRecognizerDelegate

	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}

	// MARK: - BaseTimeManager.Notification

	func baseTimeUpdated(notification: NSNotification) {
		guard let object = notification.userInfo?[BaseTimeManager.Notification.object] as? BaseTimeManagerNotificationObject else { return }
		baseTime = object.baseTime
	}

	// MARK: - ImageManagerNotification

	dynamic func imageFetched(notification: NSNotification) {
		guard let image = notification.userInfo?[ImageManager.Notification.object] as? Image else { return }

		if baseTime?.compare(image.baseTimeContext.baseTime) != .OrderedSame { return }
		if image.baseTimeContext.index != baseTimeIndex { return }

		// check region of MapView
		// issue #3
		
		renderer.setNeedsDisplay()
	}
}
