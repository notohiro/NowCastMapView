//
//  UIImage.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/4/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
	/// this is no need anymore
	var revertedImage: UIImage? {
		guard let cgImage = cgImage else { return nil }

		UIGraphicsBeginImageContext(size)

		guard let newContext = UIGraphicsGetCurrentContext() else { return nil }

		newContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
		let revertedImage = UIGraphicsGetImageFromCurrentImageContext()

		UIGraphicsEndImageContext()

		return revertedImage
	}

	func rgba255(at point: CGPoint) -> RGBA255 {
		// convert to binary data from getting pixel data
		let pixelData = cgImage?.dataProvider?.data
		let data: UnsafePointer = CFDataGetBytePtr(pixelData)

		// calculate RGBA
		let pixelInfo: Int = ((Int(size.width) * Int(point.y)) + Int(point.x)) * 4

		let r = Int(data[pixelInfo])
		let g = Int(data[pixelInfo+1])
		let b = Int(data[pixelInfo+2])
		let a = Int(data[pixelInfo+3])

		return RGBA255(red: r, green: g, blue: b, alpha: a)
	}
}
