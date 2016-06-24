//
//  ZoomLevel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public enum ZoomLevel: Int {
	static let MKZoomScaleForLevel4: CGFloat = 0.000488
	static let MKZoomScaleForLevel2: CGFloat = 0.000122

	case level2 = 4
	case level4 = 16
	case level6 = 64

	init(zoomScale: MKZoomScale) {
		if zoomScale > ZoomLevel.MKZoomScaleForLevel4 {
			self = .level6
		} else if zoomScale > ZoomLevel.MKZoomScaleForLevel2 {
			self = .level4
		} else {
			self = .level2
		}
	}

	func toURLPrefix() -> String {
		switch self {
		case .level2:
			return "zoom2"
		case .level4:
			return "zoom4"
		case .level6:
			return "zoom6"
		}
	}
}
