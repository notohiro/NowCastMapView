//
//  RainLevelColor.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

struct RainLevelColor {
	let level: Int
	let color: RGBA255

	init(level: Int, color: RGBA255) {
		self.level = level
		self.color = color
	}
}

let rainLevelColor00 = RainLevelColor(level: 0, color: RGBA255(red: 255, green: 255, blue: 255, alpha: 255))
let rainLevelColor01 = RainLevelColor(level: 0, color: RGBA255(red:   0, green:   0, blue:   0, alpha:   0))
let rainLevelColor1 = RainLevelColor(level: 1, color: RGBA255(red: 242, green: 242, blue: 255, alpha: 255))
let rainLevelColor2 = RainLevelColor(level: 2, color: RGBA255(red: 160, green: 210, blue: 255, alpha: 255))
let rainLevelColor3 = RainLevelColor(level: 3, color: RGBA255(red:  33, green: 140, blue: 255, alpha: 255))
let rainLevelColor4 = RainLevelColor(level: 4, color: RGBA255(red:   0, green:  65, blue: 255, alpha: 255))
let rainLevelColor5 = RainLevelColor(level: 5, color: RGBA255(red: 250, green: 245, blue:   0, alpha: 255))
let rainLevelColor6 = RainLevelColor(level: 6, color: RGBA255(red: 255, green: 153, blue:   0, alpha: 255))
let rainLevelColor7 = RainLevelColor(level: 7, color: RGBA255(red: 255, green:  40, blue:   0, alpha: 255))
let rainLevelColor8 = RainLevelColor(level: 8, color: RGBA255(red: 180, green:   0, blue: 104, alpha: 255))

let rainLevelColors = [rainLevelColor00, rainLevelColor01, rainLevelColor1,
                       rainLevelColor2, rainLevelColor3, rainLevelColor4,
                       rainLevelColor5, rainLevelColor6, rainLevelColor7, rainLevelColor8]
