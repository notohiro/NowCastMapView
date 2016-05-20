import MapKit
import UIKit

public class ClassA: UIViewController {
	@IBOutlet public weak var mapView: MKMapView! {
		didSet {
			if mapView !== _mapView { _mapView = nil }
		}
	}

	// to retain instance in case of init from code
	private var _mapView: MKMapView?

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		_mapView = MKMapView()
		mapView = _mapView
	}

	convenience public init(mapView: MKMapView) {
		self.init(nibName: nil, bundle: nil)
		self._mapView = mapView
		self.mapView = self._mapView
	}
}