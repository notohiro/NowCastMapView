//
//  RainLevelsModel+Result.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/10/26.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

public extension RainLevelsModel {
    enum Result {
	    public var request: Request {
    	    switch self {
    	    case let .succeeded(request, _):
	    	    return request
    	    case let .failed(request, _):
	    	    return request
    	    }
	    }

	    case succeeded(request: Request, result: RainLevels)
	    case failed(request: Request, error: Error)
    }
}
