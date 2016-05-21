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

class ViewController: UIViewController, NowCastMapViewDataSource {
	@IBOutlet weak var mapView: NowCastMapView! {
		didSet { mapView.dataSource = self }
	}

	var baseTime: NowCastBaseTime? {
		didSet { mapView.setNeedsDisplay() }
	}
	var baseTimeIndex: Int = 0 {
		didSet { mapView.setNeedsDisplay() }
	}

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

    override func viewDidLoad() {
        super.viewDidLoad()

		// register notification
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(ViewController.baseTimeUpdated(_:)), name: NowCastBaseTimeManager.Notification.name, object: nil)

		baseTime = NowCastBaseTimeManager.sharedManager.lastSavedBaseTime
    }

// MARK: - IBAction

	@IBAction func handleLongPressGesture(sender: UILongPressGestureRecognizer) {
		if (sender.state == .Began) {
			// remove specified annotations
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
}

