//
//  URL.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 8/16/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

extension URL {
	public init?(baseTime: BaseTime, index: Int, modifiers: Tile.Modifiers) {
		var forecastTimeString: String
		var viewTimeString: String

		// will view past data
		if index < 0 {
			guard let aForecastTimeString = baseTime.baseTimeString(atIndex: index) else { return nil }

			forecastTimeString = aForecastTimeString
			viewTimeString = forecastTimeString
			// will view future datad
		} else {
			guard let aForecastTimeString = baseTime.baseTimeString(atIndex: 0) else { return nil }
			guard let aViewTimeString = baseTime.baseTimeString(atIndex: index) else { return nil }

			forecastTimeString = aForecastTimeString
			viewTimeString = aViewTimeString
		}

		let urlString = String(format: "%@%@%@%@%@%@%@%ld%@%ld%@",
		                       "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/",
		                       forecastTimeString, "/", viewTimeString, "/", modifiers.zoomLevel.toURLPrefix(), "/",
		                       modifiers.longitude, "_", modifiers.latitude, ".png")

		self.init(string: urlString)
	}
}
