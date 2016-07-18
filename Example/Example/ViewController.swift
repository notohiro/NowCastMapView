//
//  ViewController.swift
//  Example
//
//  Created by Hiroshi Noto on 1/26/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import UIKit
import MapKit
import NowCastMapView

class ViewController: UIViewController, MKMapViewDelegate {
	struct Constants {
		static let numberOfForecastBars = 12
		static let numberOfPastBars = 12
	}

// MARK: - IBOutlets

	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var slider: UISlider!
	@IBOutlet weak var indexLabel: UILabel!

// MARK: - NowCastMapViewDataSource

	var baseTime: BaseTime? {
		didSet {
			if oldValue == baseTime { return }
			overlays.forEach {
				guard let baseTime = self.baseTime else { $0.1.renderer.baseTimeContext = nil; return }
				let index = $0.0
				let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: index)
				$0.1.renderer.baseTimeContext = baseTimeContext
			}
		}
	}

	var baseTimeIndex: Int = -1 {
		didSet {
			if baseTimeIndex == oldValue { return }
			indexLabel.text = "\(baseTimeIndex)"

			guard let overlay = overlays[baseTimeIndex]?.overlay else { return }
			mapView.addOverlay(overlay, level: .AboveRoads)

			let removeOverlays = mapView.overlays.filter {
				guard let renderer = mapView(mapView, rendererForOverlay: $0) as? OverlayRenderer else { return false }
				return renderer.baseTimeContext?.index != baseTimeIndex
			}
			mapView.removeOverlays(removeOverlays)
		}
	}

// MARK: - Other Variables

	var overlays = [Int : (overlay: Overlay, renderer: OverlayRenderer)]()
	let imageManager = ImageManager.sharedManager

	var annotation: MKPointAnnotation? {
		didSet {
			if let baseTime = baseTime, annotation = annotation {
				let _ = RainLevels(baseTime: baseTime, coordinate: annotation.coordinate) { rainLevels, error in
					NSOperationQueue.mainQueue().addOperationWithBlock {
						guard let baseTimeString = rainLevels.baseTime.baseTimeString(atIndex: 0) else { return }
						guard let level = rainLevels.rainLevel(atBaseTimeIndex: 0)?.level else { return }

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

// MARK: - Application Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

		// Initialize mapView
		mapView.delegate = self

		// Initialize Overlay and Renderer
		for index in -Constants.numberOfPastBars...Constants.numberOfForecastBars {
			let overlay = Overlay()
			let renderer = OverlayRenderer(overlay: overlay)
			overlays[index] = (overlay, renderer)
		}

		// register notification
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(ViewController.baseTimeUpdated(_:)), name: BaseTimeManager.Notification.name, object: nil)

		// restore last baseTime
		baseTime = BaseTimeManager.sharedManager.lastSavedBaseTime

		slider.maximumValue = Float(Constants.numberOfForecastBars)
		slider.minimumValue = -Float(Constants.numberOfPastBars)
		slider.value = 0
		baseTimeIndex = 0
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

	@IBAction func sliderValueChanged(sender: UISlider) {
		baseTimeIndex = Int(floor(sender.value))
		sender.value = Float(baseTimeIndex)
	}

// MARK: - MKMapViewDelegate

	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		return overlays.filter { $0.1.overlay === overlay }.first!.1.renderer
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
}
