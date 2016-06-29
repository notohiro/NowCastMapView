//
//  UIImage+Reverted.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/29/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
	func xReverted() -> UIImage {
		UIGraphicsBeginImageContext(size)
		let imageContext = UIGraphicsGetCurrentContext()
		CGContextDrawImage(imageContext, CGRect.init(x: 0, y: 0, width: size.width, height: size.height), CGImage)
		let revertedImg = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return revertedImg
	}
}
