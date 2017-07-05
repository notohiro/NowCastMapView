//
//  NCError.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/06/27.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import Foundation
import CoreLocation

public enum NCError: Error {
	public enum TileFailedReason {
		case internalError
		case modifiersInitializationFailedMods(zoomLevel: ZoomLevel, latitiude: Int, Longitude: Int)
		case modifiersInitializationFailedCoordinate(zoomLevel: ZoomLevel, coordinate: CLLocationCoordinate2D)
		case urlInitializationFailed
		case imageProcessingFailed
	}

	public enum RainLevelsFailedReason {
		case tileInvalid
		case colorInvalid(color: RGBA255)
	}

	case outOfService
	case tileFailed(reason: TileFailedReason)
	case rainLevelsFailed(reason: RainLevelsFailedReason)
	case unknown
}
