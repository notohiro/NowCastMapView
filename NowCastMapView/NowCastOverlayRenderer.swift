//
//  NowCastOverlayRenderer.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public class NowCastOverlayRenderer: MKOverlayRenderer {
	static let DefaultBackgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.6)
	internal var mapView: NowCastMapView?
	internal var backgroundColor = NowCastOverlayRenderer.DefaultBackgroundColor {
		didSet {
			backgroundImage = NowCastOverlayRenderer.makeImageFromColor(backgroundColor)
		}
	}
	private var backgroundImage: UIImage

	static private func makeImageFromColor(color: UIColor) -> UIImage {
		let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
		UIGraphicsBeginImageContext(rect.size)
		let bgContext = UIGraphicsGetCurrentContext()

		CGContextSetFillColorWithColor(bgContext, color.CGColor)
		CGContextFillRect(bgContext, rect)

		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}

	override init(overlay: MKOverlay) {
		backgroundImage = NowCastOverlayRenderer.makeImageFromColor(backgroundColor)
		super.init(overlay: overlay)
	}

	internal init(overlay: MKOverlay, backgroundColor: UIColor) {
		backgroundImage = NowCastOverlayRenderer.makeImageFromColor(backgroundColor)
		super.init(overlay: overlay)
	}

	override public func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
		mapView?.currentZoomScale = zoomScale

		if let ncImages = mapView?.dataSource?.nowCastImages(inMapRect: mapRect, forZoomScale: zoomScale) {
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

	override public func canDrawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
		if let dataSource = mapView?.dataSource {
			return dataSource.isServiceAvailable(mapRect)
		}
		else {
			return false
		}
	}
}
