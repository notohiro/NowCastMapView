//
//  RainLevel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/23/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit

public class RainLevel {
	public var level: Int?
	private var _color: RGBA255

	init(color: RGBA255) {
		self._color = color

		level = rainLevelColors.filter {
			$0.color.red == color.red && $0.color.green == color.green && $0.color.blue == color.blue
		}.first?.level
	}

	func toRGBA255() -> RGBA255? {
		guard let level = self.level else { return nil }

		if level == 0 { return rainLevelColor00.color }
		return rainLevelColors.filter { $0.level == level }.first?.color
	}

	public func toUIColor() -> UIColor? {
		guard let colorAsRGBA255 = toRGBA255() else { return nil }

		let red = CGFloat(Double(colorAsRGBA255.red)/255.0)
		let green = CGFloat(Double(colorAsRGBA255.green)/255.0)
		let blue = CGFloat(Double(colorAsRGBA255.blue)/255.0)
		return UIColor(red: red, green: green, blue: blue, alpha: CGFloat(colorAsRGBA255.alpha))
	}
}
