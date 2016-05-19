//
//  UIImage+UIColorAtPoint.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/4/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit

internal struct RGBA255: Equatable {
	let red: Int
	let green: Int
	let blue: Int
	let alpha: Int

	init(red: Int, green: Int, blue: Int, alpha: Int) {
		self.red = RGBA255.round(red)
		self.green = RGBA255.round(green)
		self.blue = RGBA255.round(blue)
		self.alpha = RGBA255.round(alpha)
	}

	private static func round(value: Int) -> Int {
		if value < 0 { return 0 }
		if 255 < value { return 255 }
		else { return value }
	}
}

internal func ==(lhs: RGBA255, rhs: RGBA255) -> Bool {
	return lhs.red == rhs.red && lhs.green == rhs.green && lhs.blue == rhs.blue && lhs.alpha == rhs.alpha ? true : false
}

extension UIImage {
	func color(atPoint point: CGPoint) -> RGBA255 {
		//ピクセルデータ取得してバイナリ化
		let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
		let data: UnsafePointer = CFDataGetBytePtr(pixelData)

		//RGBおよびアルファ値を取得します
		let pixelInfo: Int = ((Int(self.size.width) * Int(point.y)) + Int(point.x)) * 4

		let r = Int(data[pixelInfo])
		let g = Int(data[pixelInfo+1])
		let b = Int(data[pixelInfo+2])
		let a = Int(data[pixelInfo+3])

		return RGBA255(red: r, green: g, blue: b, alpha: a)
	}
}
