//
//  NCError.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2017/06/27.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import Foundation

public enum NCError: Error {
	public enum RequestProcessingFailedReason {
		case modifiersInitializationFailed
		case urlInitializationFailed
	}

	public enum RainLevelsProcessingFailedReason {
		case tileDownloadingFailed
		case tileInvalid
		case colorInvalid(color: RGBA255)
	}

	case outOfService
	case requestProcessingFailed(reason: RequestProcessingFailedReason)
	case rainLevelsProcessingFailed(reason: RainLevelsProcessingFailedReason)
	case unknown
}
