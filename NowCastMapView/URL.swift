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
		if !baseTime.range.contains(index) { return nil }
		let forecastTime: String = index < 0 ? baseTime[index] : baseTime[0]
		let viewTime: String = index < 0 ? forecastTime : baseTime[index]

		let urlString = String(format: "%@%@%@%@%@%@%@%ld%@%ld%@",
		                       "http://www.jma.go.jp/jp/highresorad/highresorad_tile/HRKSNC/",
		                       forecastTime, "/", viewTime, "/", modifiers.zoomLevel.toURLPrefix(), "/",
		                       modifiers.longitude, "_", modifiers.latitude, ".png")

		self.init(string: urlString)
	}
}
