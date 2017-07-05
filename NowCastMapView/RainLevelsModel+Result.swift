//
//  RainLevelsModel+Result.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/26.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

extension RainLevelsModel {
	public enum Result {
		public var request: Request {
			switch self {
			case let .succeeded(_request, _):
				return _request
			case let .failed(_request, _):
				return _request
			}
		}

		case succeeded(request: Request, result: RainLevels)
		case failed(request: Request, error: Error)
	}
}
