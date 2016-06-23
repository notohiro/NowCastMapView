//
//  OverlayRenderer.swift
//  MapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public protocol OverlayRendererDataSource {
	func Images(inMapRect mapRect: MKMapRect, forZoomScale zoomScale: MKZoomScale) -> [Image]?
}

public class OverlayRenderer: MKOverlayRenderer {
	static let DefaultBackgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.6)

	public var dataSource: OverlayRendererDataSource?
	public var backgroundColor = OverlayRenderer.DefaultBackgroundColor {
		didSet {
			backgroundImage = OverlayRenderer.makeImage(fromUIColor: backgroundColor)
		}
	}
	private var backgroundImage: UIImage

	static private func makeImage(fromUIColor color: UIColor) -> UIImage {
		let rect = CGRect.init(x: 0, y: 0, width: 1.0, height: 1.0)
		UIGraphicsBeginImageContext(rect.size)
		let bgContext = UIGraphicsGetCurrentContext()

		CGContextSetFillColorWithColor(bgContext, color.CGColor)
		CGContextFillRect(bgContext, rect)

		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}

	override public init(overlay: MKOverlay) {
		backgroundImage = OverlayRenderer.makeImage(fromUIColor: backgroundColor)
		super.init(overlay: overlay)
	}

	init(overlay: MKOverlay, backgroundColor: UIColor) {
		backgroundImage = OverlayRenderer.makeImage(fromUIColor: backgroundColor)
		super.init(overlay: overlay)
	}

	override public func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
		dataSource?.Images(inMapRect: mapRect, forZoomScale: zoomScale)?.forEach { image in
			if let imageData = image.imageData, imageReference = image.imageData?.CGImage {
				UIGraphicsBeginImageContext(imageData.size)
				let imageContext = UIGraphicsGetCurrentContext()
				CGContextDrawImage(imageContext, CGRect.init(x: 0, y: 0, width: imageData.size.width, height: imageData.size.height), imageReference)
				let revertedImg = UIGraphicsGetImageFromCurrentImageContext()
				UIGraphicsEndImageContext()

				CGContextClearRect(context, rectForMapRect(image.mapRect))
				CGContextSetAlpha(context, 0.6)
				CGContextDrawImage(context, rectForMapRect(image.mapRect), revertedImg.CGImage)
			} else {
				CGContextDrawImage(context, rectForMapRect(image.mapRect), backgroundImage.CGImage)
			}
		}
	}
}
