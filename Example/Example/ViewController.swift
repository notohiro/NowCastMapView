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

class ViewController: UIViewController {

	struct Constants {
		static let numberOfForecastBars = 12
		static let numberOfPastBars = 12
	}

// MARK: - IBOutlets

	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var slider: UISlider!
	@IBOutlet weak var indexLabel: UILabel!

// MARK: - NowCastMapView Variables

	let baseTimeModel = BaseTimeModel()
	var baseTime: BaseTime? {
		didSet {
			if oldValue == baseTime { return }
			if let baseTime = baseTime {
				print("baseTime updated: \(baseTime)")

				renderers.removeAll()
				mapView.removeOverlays(mapView.overlays)

				let overlay = Overlay()
				for index in -Constants.numberOfPastBars...Constants.numberOfForecastBars {
					let renderer = OverlayRenderer(overlay: overlay, baseTime: baseTime, index: index)

					renderers[index] = renderer
				}
				OperationQueue.main.addOperation {
					self.mapView.add(overlay, level: .aboveRoads)
					self.mapView.setNeedsDisplay()
				}

				rainLevelsModel = RainLevelsModel(baseTime: baseTime)
				rainLevelsModel?.delegate = self
			}
		}
	}

	var index: Int = 0 {
		didSet {
			if index == oldValue { return }
			indexLabel.text = "\(index)"
			let overlays = mapView.overlays
			mapView.removeOverlays(overlays)
			mapView.addOverlays(overlays)
		}
	}

	var rainLevelsModel: RainLevelsModel?

// MARK: - Other Variables

	var renderers = [Int : OverlayRenderer]()

	var annotation: MKPointAnnotation? {
		didSet {
			if let annotation = annotation {
				let request = RainLevelsModel.Request(coordinate: annotation.coordinate, range: 0...0)
				rainLevelsModel?.rainLevels(with: request)
			}
		}
	}

// MARK: - Application Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

		// Initialize mapView
		mapView.delegate = self

		// register notification
		baseTimeModel.delegate = self
		baseTimeModel.fetch()
		baseTimeModel.fetchInterval =  3

		slider.maximumValue = Float(Constants.numberOfForecastBars)
		slider.minimumValue = -Float(Constants.numberOfPastBars)
		indexLabel.text = "\(index)"
    }

// MARK: - IBAction

	@IBAction func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
		if (sender.state == .began) {
			// remove existing annotations
			mapView.removeAnnotations(mapView.annotations)

			// add annotation
			let touchedPoint = sender.location(in: mapView)
			let touchCoordinate = mapView.convert(touchedPoint, toCoordinateFrom: mapView)

			let anno = MKPointAnnotation()
			anno.coordinate = touchCoordinate
			annotation = anno
			mapView.addAnnotation(anno)
		}
	}

	@IBAction func sliderValueChanged(_ sender: UISlider) {
		index = Int(floor(sender.value))
		sender.value = Float(index)
	}



// MARK: - UIGestureRecognizerDelegate

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
}

// MARK: - BaseTimeModelDelegate

extension ViewController: BaseTimeModelDelegate {
	public func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?) {
		self.baseTime = baseTime
	}
}

// MARK: - BaseTimeModelDelegate

extension ViewController: RainLevelsModelDelegate {
	func rainLevelsModel(_ model: RainLevelsModel, result: RainLevelsModel.Result) {
		switch result {
		case let .succeeded(request: _, result: result):
			guard let level = result.levels[0]?.rawValue else { return }
			let message = "level = " + String(level)
			let alertController = UIAlertController(title: "RainLevels", message: message, preferredStyle: .alert)

			let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
			alertController.addAction(defaultAction)

			OperationQueue.main.addOperation {
				self.present(alertController, animated: true, completion: nil)
			}
		case .failed(request: _):
			let message = "failed"
			let alertController = UIAlertController(title: "RainLevels", message: message, preferredStyle: .alert)

			let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
			alertController.addAction(defaultAction)

			OperationQueue.main.addOperation {
				self.present(alertController, animated: true, completion: nil)
			}
		default:
			break
		}
	}
}

// MARK: - MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		return renderers[index]!
	}
}
