//
//  NowCastRainLevels.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/1/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

struct NowCastRainLevelColor {
	let level: Int
	let color: RGBA255

	init(level: Int, color: RGBA255) {
		self.level = level
		self.color = color
	}
}

var NowCastRainLevelColor00 = NowCastRainLevelColor(level: 0, color: RGBA255(red: 255, green: 255, blue: 255, alpha: 255))
var NowCastRainLevelColor01 = NowCastRainLevelColor(level: 0, color: RGBA255(red:   0, green:   0, blue:   0, alpha:   0))
var NowCastRainLevelColor1 = NowCastRainLevelColor(level: 1, color: RGBA255(red: 242, green: 242, blue: 255, alpha: 255))
var NowCastRainLevelColor2 = NowCastRainLevelColor(level: 2, color: RGBA255(red: 160, green: 210, blue: 255, alpha: 255))
var NowCastRainLevelColor3 = NowCastRainLevelColor(level: 3, color: RGBA255(red:  33, green: 140, blue: 255, alpha: 255))
var NowCastRainLevelColor4 = NowCastRainLevelColor(level: 4, color: RGBA255(red:   0, green:  65, blue: 255, alpha: 255))
var NowCastRainLevelColor5 = NowCastRainLevelColor(level: 5, color: RGBA255(red: 250, green: 245, blue:   0, alpha: 255))
var NowCastRainLevelColor6 = NowCastRainLevelColor(level: 6, color: RGBA255(red: 255, green: 153, blue:   0, alpha: 255))
var NowCastRainLevelColor7 = NowCastRainLevelColor(level: 7, color: RGBA255(red: 255, green:  40, blue:   0, alpha: 255))
var NowCastRainLevelColor8 = NowCastRainLevelColor(level: 8, color: RGBA255(red: 180, green:   0, blue: 104, alpha: 255))

let NowCastRainLevelColors = [NowCastRainLevelColor00, NowCastRainLevelColor01, NowCastRainLevelColor1,
                                       NowCastRainLevelColor2,  NowCastRainLevelColor3,  NowCastRainLevelColor4,
                                       NowCastRainLevelColor5,  NowCastRainLevelColor6,  NowCastRainLevelColor7, NowCastRainLevelColor8]

public class NowCastRainLevel {
	public var level: Int?
	private var _color: RGBA255

	init(color: RGBA255) {
		self._color = color

		for rainLevel in NowCastRainLevelColors {
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
			if level == 0 { return NowCastRainLevelColor00.color }
			for rainLevel in NowCastRainLevelColors {
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

// retain NowCastRainLevels Objects for processing request
private struct NowCastRainLevelsManager {
	static var _rainLevels = [String : NowCastRainLevels]()
	func add(rainLevels: NowCastRainLevels) {
		if let hash = rainLevels.hash {	NowCastRainLevelsManager._rainLevels[hash] = rainLevels }
	}

	func remove(rainLevels: NowCastRainLevels) {
		if let hash = rainLevels.hash {	NowCastRainLevelsManager._rainLevels.removeValueForKey(hash) }
	}
}

public enum NowCastRainLevelsState: Int {
	case initializing, initialized, isFetchingImages, allImagesFetched, calculating, completedWithError, completedSuccessfully
}

public class NowCastRainLevels: CustomStringConvertible {
	public struct Notification {
		public static let name = "NowCastRainLevelsNotification"
		public static let object = "object"
	}

	public let baseTime: NowCastBaseTime
	public let coordinate: CLLocationCoordinate2D
	public var rainLevels = [String : NowCastRainLevel]()
	public var state: NowCastRainLevelsState = .initializing {
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

	private static let sharedManager = NowCastRainLevelsManager()
	private unowned var imageManager = NowCastImageManager.sharedManager
	private var handler: ((NowCastRainLevels, NSError?) -> Void)?
	private var nowCastImages = [String : NowCastImage]()

	public init?(baseTime: NowCastBaseTime, coordinate: CLLocationCoordinate2D, completionHandler: ((NowCastRainLevels, NSError?) -> Void)?) {
		self.baseTime = baseTime
		self.coordinate = coordinate
		self.handler = completionHandler

		if imageManager.isServiceAvailable(atCoordinate: coordinate) == false { return nil }

		NowCastRainLevels.sharedManager.add(self)
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(NowCastRainLevels.newImageFetched(_:)), name: NowCastImageManager.Notification.name, object: nil)

		for index in baseTime.range() {
			if let nowCastImage = imageManager.image(atCoordinate: coordinate, zoomScale: 0.0005, baseTime: baseTime, baseTimeIndex: index, priority: NowCastDownloadPriorityHigh) {
				nowCastImages[nowCastImage.imageURL.absoluteString] = nowCastImage
			}
			else { return nil }
		}

		state = .initialized
		checkAllImagesFetched() // can't call didSet from init()
	}

	public func rainLevel(atBaseTimeIndex baseTimeIndex: Int) -> NowCastRainLevel? {
		if allImagesFetched() == false { return nil }

		for (key, nowCastImage) in nowCastImages {
			if nowCastImage.baseTimeIndex == baseTimeIndex {
				return rainLevels[key]
			}
		}

		return nil
	}

	// newImageFetched has chance to be called before initialization completed
	private func isInitialized() -> Bool {
		return nowCastImages.count == baseTime.count() ? true : false
	}

	private func checkAllImagesFetched() {
		NSOperationQueue().addOperationWithBlock() {
			if self.state == .initializing { return }
			for (_, nowCastImage) in self.nowCastImages { if nowCastImage.image == nil { self.state = .isFetchingImages; return } }
			self.state = .allImagesFetched
		}
	}

	private func allImagesFetched() -> Bool {
		if isInitialized() == false { return false }

		for (_, nowCastImage) in nowCastImages {
			if nowCastImage.image == nil { return false }
		}

		return true
	}

	// this function run in not main queue when instance initialized
	private func calculateRainLevels() {
		state = .calculating

		rainLevels = [String : NowCastRainLevel]()

		for (_, nowCastImage) in nowCastImages {
			////////// impl multi threadings
			if let color = nowCastImage.color(atCoordinate: coordinate) {
				let rainLevel = NowCastRainLevel(color: color)
				rainLevels[nowCastImage.imageURL.absoluteString] = rainLevel
			}
		}

		state = .completedSuccessfully
	}

	private func notifyAndExecHandler() {
		handler?(self, error)

		var notifyObject = [NSObject : AnyObject]()
		notifyObject[NowCastRainLevels.Notification.object] = self
		let nc = NSNotificationCenter.defaultCenter()
		nc.postNotificationName(NowCastRainLevels.Notification.name, object: nil, userInfo:notifyObject)
	}

	private func finalizeObject() {
		let nc = NSNotificationCenter.defaultCenter()
		nc.removeObserver(self)
		NowCastRainLevels.sharedManager.remove(self)
		handler = nil
	}

// MARK: - NowCastImageManagerNotification

	dynamic public func newImageFetched(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let image = userInfo[NowCastImageManager.Notification.object] as? NowCastImage {
				// check this notification is for this object
				if nowCastImages[image.imageURL.absoluteString] != nil {
					if let error = userInfo[NowCastImageManager.Notification.error] as? NSError {
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