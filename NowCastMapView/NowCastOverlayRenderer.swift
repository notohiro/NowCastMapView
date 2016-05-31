//
//  NowCastOverlayRenderer.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public protocol NowCastOverlayRendererDataSource {
	func nowCastImages(inMapRect mapRect: MKMapRect, forZoomScale zoomScale: MKZoomScale) -> [NowCastImage]?
}

public class NowCastOverlayRenderer: MKOverlayRenderer {
	static let DefaultBackgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.6)
	
	public var dataSource: NowCastOverlayRendererDataSource?
	public var backgroundColor = NowCastOverlayRenderer.DefaultBackgroundColor {
		didSet {
			backgroundImage = NowCastOverlayRenderer.makeImage(fromUIColor: backgroundColor)
		}
	}
	private var backgroundImage: UIImage

	static private func makeImage(fromUIColor color: UIColor) -> UIImage {
		let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
		UIGraphicsBeginImageContext(rect.size)
		let bgContext = UIGraphicsGetCurrentContext()

		CGContextSetFillColorWithColor(bgContext, color.CGColor)
		CGContextFillRect(bgContext, rect)

		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}

	override public init(overlay: MKOverlay) {
		backgroundImage = NowCastOverlayRenderer.makeImage(fromUIColor: backgroundColor)
		super.init(overlay: overlay)
	}

	init(overlay: MKOverlay, backgroundColor: UIColor) {
		backgroundImage = NowCastOverlayRenderer.makeImage(fromUIColor: backgroundColor)
		super.init(overlay: overlay)
	}

	override public func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
		if let ncImages = dataSource?.nowCastImages(inMapRect: mapRect, forZoomScale: zoomScale) {
			for ncImage in ncImages {
				if let image = ncImage.image, imageReference = ncImage.image?.CGImage {
					UIGraphicsBeginImageContext(image.size)
					let imageContext = UIGraphicsGetCurrentContext()
					CGContextDrawImage(imageContext, CGRectMake( 0, 0, image.size.width, image.size.height), imageReference)
					let revertedImg = UIGraphicsGetImageFromCurrentImageContext()
					UIGraphicsEndImageContext()

					CGContextClearRect(context, rectForMapRect(ncImage.mapRect))
					CGContextSetAlpha(context, 0.6);
					CGContextDrawImage(context, rectForMapRect(ncImage.mapRect), revertedImg.CGImage)
				}
				else {
					CGContextDrawImage(context, rectForMapRect(ncImage.mapRect), backgroundImage.CGImage)
				}
			}
		}
	}
}
