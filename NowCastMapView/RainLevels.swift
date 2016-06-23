//
//  RainLevels.swift
//  MapView
//
//  Created by Hiroshi Noto on 2/1/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

struct RainLevelColor {
	let level: Int
	let color: RGBA255

	init(level: Int, color: RGBA255) {
		self.level = level
		self.color = color
	}
}

var RainLevelColor00 = RainLevelColor(level: 0, color: RGBA255(red: 255, green: 255, blue: 255, alpha: 255))
var RainLevelColor01 = RainLevelColor(level: 0, color: RGBA255(red:   0, green:   0, blue:   0, alpha:   0))
var RainLevelColor1 = RainLevelColor(level: 1, color: RGBA255(red: 242, green: 242, blue: 255, alpha: 255))
var RainLevelColor2 = RainLevelColor(level: 2, color: RGBA255(red: 160, green: 210, blue: 255, alpha: 255))
var RainLevelColor3 = RainLevelColor(level: 3, color: RGBA255(red:  33, green: 140, blue: 255, alpha: 255))
var RainLevelColor4 = RainLevelColor(level: 4, color: RGBA255(red:   0, green:  65, blue: 255, alpha: 255))
var RainLevelColor5 = RainLevelColor(level: 5, color: RGBA255(red: 250, green: 245, blue:   0, alpha: 255))
var RainLevelColor6 = RainLevelColor(level: 6, color: RGBA255(red: 255, green: 153, blue:   0, alpha: 255))
var RainLevelColor7 = RainLevelColor(level: 7, color: RGBA255(red: 255, green:  40, blue:   0, alpha: 255))
var RainLevelColor8 = RainLevelColor(level: 8, color: RGBA255(red: 180, green:   0, blue: 104, alpha: 255))

let RainLevelColors = [RainLevelColor00, RainLevelColor01, RainLevelColor1,
                                       RainLevelColor2,  RainLevelColor3,  RainLevelColor4,
                                       RainLevelColor5,  RainLevelColor6,  RainLevelColor7, RainLevelColor8]

public class RainLevel {
	public var level: Int?
	private var _color: RGBA255

	init(color: RGBA255) {
		self._color = color

		for rainLevel in RainLevelColors {
			if	rainLevel.color.red == color.red &&
				rainLevel.color.green == color.green &&
				rainLevel.color.blue == color.blue {
				level = rainLevel.level
				break
			}
		}
	}

	func toRGBA255() -> RGBA255? {
		if let level = self.level {
			if level == 0 { return RainLevelColor00.color }
			for rainLevel in RainLevelColors {
				if rainLevel.level == level { return rainLevel.color }
			}
		}

		return nil
	}

	public func toUIColor() -> UIColor? {
		if let colorAsRGBA255 = toRGBA255() {
			let red = CGFloat(Double(colorAsRGBA255.red)/255.0)
			let green = CGFloat(Double(colorAsRGBA255.green)/255.0)
			let blue = CGFloat(Double(colorAsRGBA255.blue)/255.0)
			return UIColor(red: red, green: green, blue: blue, alpha: CGFloat(colorAsRGBA255.alpha))
		}

		return nil
	}
}

// retain RainLevels Objects for processing request
private struct RainLevelsManager {
	static var _rainLevels = [String : RainLevels]()
	func add(rainLevels: RainLevels) {
		if let hash = rainLevels.hash {	RainLevelsManager._rainLevels[hash] = rainLevels }
	}

	func remove(rainLevels: RainLevels) {
		if let hash = rainLevels.hash {	RainLevelsManager._rainLevels.removeValueForKey(hash) }
	}
}

public enum RainLevelsState: Int {
	case initializing, initialized, isFetchingImages, allImagesFetched, calculating, completedWithError, completedSuccessfully
}

public class RainLevels: CustomStringConvertible {
	public struct Notification {
		public static let name = "RainLevelsNotification"
		public static let object = "object"
	}

	public let baseTime: BaseTime
	public let coordinate: CLLocationCoordinate2D
	public var rainLevels = [String : RainLevel]()
	public var state: RainLevelsState = .initializing {
		didSet {
			if oldValue.rawValue >= state.rawValue { state = oldValue; return }

			switch state {
			case .initializing, .initialized:
				break
			case .isFetchingImages:
				break
			case .allImagesFetched:
				calculateRainLevels()
			case .calculating:
				break
			case .completedWithError, .completedSuccessfully:
				notifyAndExecHandler()
				finalizeObject()
			}
		}
	}
	public var error: NSError?
	public var hash: String? {
		return baseTime.baseTimeString(atIndex: 0).flatMap { $0 + "\(coordinate.latitude)" + "\(coordinate.longitude)" }
	}
	public var description: String {
		return hash ?? "error"
	}

	private static let sharedManager = RainLevelsManager()
	private unowned var imageManager = ImageManager.sharedManager
	private var handler: ((RainLevels, NSError?) -> Void)?
	private var images = [String : Image]()

	public init?(baseTime: BaseTime, coordinate: CLLocationCoordinate2D, completionHandler: ((RainLevels, NSError?) -> Void)?) {
		self.baseTime = baseTime
		self.coordinate = coordinate
		self.handler = completionHandler

		if imageManager.isServiceAvailable(atCoordinate: coordinate) == false { return nil }

		RainLevels.sharedManager.add(self)
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(RainLevels.newImageFetched(_:)), name: ImageManager.Notification.name, object: nil)

		for index in baseTime.range() {
			let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: index)
			if let Image = imageManager.image(atCoordinate: coordinate, zoomScale: 0.0005, baseTimeContext: baseTimeContext, priority: .High) {
				images[Image.url.absoluteString] = Image
			}
			else { return nil }
		}

		state = .initialized
		checkAllImagesFetched() // can't call didSet from init()
	}

	public func rainLevel(atBaseTimeIndex baseTimeIndex: Int) -> RainLevel? {
		if allImagesFetched() == false { return nil }

		for (key, image) in images {
			if image.baseTimeContext.index == baseTimeIndex {
				return rainLevels[key]
			}
		}

		return nil
	}

	// newImageFetched has chance to be called before initialization completed
	private func isInitialized() -> Bool {
		return images.count == baseTime.count() ? true : false
	}

	private func checkAllImagesFetched() {
		NSOperationQueue().addOperationWithBlock() {
			if self.state == .initializing { return }
			for (_, image) in self.images { if image.imageData == nil { self.state = .isFetchingImages; return } }
			self.state = .allImagesFetched
		}
	}

	private func allImagesFetched() -> Bool {
		if isInitialized() == false { return false }

		for (_, image) in images {
			if image.imageData == nil { return false }
		}

		return true
	}

	// this function run in not main queue when instance initialized
	private func calculateRainLevels() {
		state = .calculating

		rainLevels = [String : RainLevel]()

		for (_, image) in images {
			////////// impl multi threadings
			if let color = image.color(atCoordinate: coordinate) {
				let rainLevel = RainLevel(color: color)
				rainLevels[image.url.absoluteString] = rainLevel
			}
		}

		state = .completedSuccessfully
	}

	private func notifyAndExecHandler() {
		handler?(self, error)

		var notifyObject = [NSObject : AnyObject]()
		notifyObject[RainLevels.Notification.object] = self
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(RainLevels.Notification.name, object: nil, userInfo:notifyObject)
	}

	private func finalizeObject() {
		let nc = NSNotificationCenter.defaultCenter()
		nc.removeObserver(self)
		RainLevels.sharedManager.remove(self)
		handler = nil
	}

// MARK: - ImageManagerNotification

	dynamic public func newImageFetched(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let image = userInfo[ImageManager.Notification.object] as? Image {
				// check this notification is for this object
				if images[image.url.absoluteString] != nil {
					if let error = userInfo[ImageManager.Notification.error] as? NSError {
						self.error = error
						state = .completedWithError
						return
					}

					checkAllImagesFetched()
				}
			}
		}
	}
}