//
//  Constants.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import AwesomeCache

public struct Constants {
	// define coordinate of upper left and bottom right
	static let originLatitude: Double    = 61
	static let originLongitude:	Double   = 100
	static let terminalLatitude: Double  = 7
	static let terminalLongitude: Double = 170
}

public enum DownloadPriority: Float {
	case Urgent		= 1.0
	case High		= 0.8
	case Default	= 0.6
	case Low		= 0.4
}
