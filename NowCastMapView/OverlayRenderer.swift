//
//  OverlayRenderer.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

public class OverlayRenderer: MKOverlayRenderer {
	static let DefaultBackgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.6)

	public var baseTimeContext: BaseTimeContext? {
		didSet { setNeedsDisplay() }
	}
	public var backgroundColor = OverlayRenderer.DefaultBackgroundColor

	override public init(overlay: MKOverlay) {
		super.init(overlay: overlay)

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(OverlayRenderer.imageFetched(_:)), name: ImageManager.Notification.name, object: nil)
	}

	override public func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
		guard let baseTimeContext = self.baseTimeContext else {
			var red: CGFloat = 0
			var green: CGFloat = 0
			var blue: CGFloat = 0
			var alpha: CGFloat = 0
			backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

			CGContextSetRGBFillColor(context, red, green, blue, alpha)
			CGContextFillRect(context, rectForMapRect(mapRect))
			return
		}

		let imageManager = ImageManager.sharedManager
		let images = imageManager.images(inMapRect: mapRect, zoomScale: zoomScale, baseTimeContext: baseTimeContext, priority: .High)

		images.forEach { image in
			if let imageData = image.xRevertedImageData, imageReference = image.xRevertedImageData?.CGImage {
				CGContextClearRect(context, rectForMapRect(image.mapRect))
				CGContextSetAlpha(context, 0.6)
				CGContextDrawImage(context, rectForMapRect(image.mapRect), imageReference)
			} else {
				var red: CGFloat = 0
				var green: CGFloat = 0
				var blue: CGFloat = 0
				var alpha: CGFloat = 0
				backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

				CGContextSetRGBFillColor(context, red, green, blue, alpha)
				CGContextFillRect(context, rectForMapRect(image.mapRect))
			}
		}
	}

// MARK: - ImageManagerNotification

	func imageFetched(notification: NSNotification) {
		guard let image = notification.userInfo?[ImageManager.Notification.object] as? Image else { return }

		if baseTimeContext?.baseTime != image.baseTimeContext.baseTime { return }
		if baseTimeContext?.index != image.baseTimeContext.index { return }

		setNeedsDisplayInMapRect(image.mapRect)
	}
}
