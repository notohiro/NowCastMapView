//
//  RainLevel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit

public enum RainLevel: Int {
	case level0 = 0, level1, level2, level3, level4, level5, level6, level7, level8

	static let rgba255ToRainLevel = [
		RGBA255(red: 255, green: 255, blue: 255, alpha: 255) : 0,
		RGBA255(red: 255, green: 255, blue: 255, alpha:   0) : 0,
		RGBA255(red:   0, green:   0, blue:   0, alpha:   0) : 0,
		RGBA255(red: 242, green: 242, blue: 255, alpha: 255) : 1,
		RGBA255(red: 160, green: 210, blue: 255, alpha: 255) : 2,
		RGBA255(red:  33, green: 140, blue: 255, alpha: 255) : 3,
		RGBA255(red:   0, green:  65, blue: 255, alpha: 255) : 4,
		RGBA255(red: 250, green: 245, blue:   0, alpha: 255) : 5,
		RGBA255(red: 255, green: 153, blue:   0, alpha: 255) : 6,
		RGBA255(red: 255, green:  40, blue:   0, alpha: 255) : 7,
		RGBA255(red: 180, green:   0, blue: 104, alpha: 255) : 8
	]

	static let rainLevelToColor = [
		UIColor(rgba255: RGBA255(red: 255, green: 255, blue: 255, alpha: 255)),
		UIColor(rgba255: RGBA255(red: 242, green: 242, blue: 255, alpha: 255)),
		UIColor(rgba255: RGBA255(red: 160, green: 210, blue: 255, alpha: 255)),
		UIColor(rgba255: RGBA255(red:  33, green: 140, blue: 255, alpha: 255)),
		UIColor(rgba255: RGBA255(red:   0, green:  65, blue: 255, alpha: 255)),
		UIColor(rgba255: RGBA255(red: 250, green: 245, blue:   0, alpha: 255)),
		UIColor(rgba255: RGBA255(red: 255, green: 153, blue:   0, alpha: 255)),
		UIColor(rgba255: RGBA255(red: 255, green:  40, blue:   0, alpha: 255)),
		UIColor(rgba255: RGBA255(red: 180, green:   0, blue: 104, alpha: 255))
	]

	static let min = 0
	static let max = 8

	init?(rgba255: RGBA255) {
		if let level = RainLevel.rgba255ToRainLevel[rgba255] {
			self.init(rawValue: level)
		} else {
			return nil
		}
	}

	public var color: UIColor {
		return RainLevel.rainLevelToColor[self.rawValue]
	}
}
