//
//  RainLevels.swift
//  MapView
//
//  Created by Hiroshi Noto on 2/1/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import MapKit

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

	private let sharedManager = RainLevelsManager.sharedManager
	private var imageManager = ImageManager.sharedManager
	private var handler: ((RainLevels, NSError?) -> Void)?
	private var images = [String : Image]()

	public init?(baseTime: BaseTime, coordinate: CLLocationCoordinate2D, completionHandler: ((RainLevels, NSError?) -> Void)?) {
		self.baseTime = baseTime
		self.coordinate = coordinate
		self.handler = completionHandler

		if imageManager.isServiceAvailable(atCoordinate: coordinate) == false { return nil }

		sharedManager.add(self)

		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(RainLevels.newImageFetched(_:)), name: ImageManager.Notification.name, object: nil)

		for index in baseTime.range() {
			let baseTimeContext = BaseTimeContext(baseTime: baseTime, index: index)
			guard let image = imageManager.image(atCoordinate: coordinate, zoomScale: 0.0005, baseTimeContext: baseTimeContext, priority: .High) else {
				sharedManager.remove(self)
				return nil
			}

			images[image.url.absoluteString] = image
		}

		state = .initialized
		checkAllImagesFetched() // can't call didSet from init()
	}

	public func rainLevel(atBaseTimeIndex baseTimeIndex: Int) -> RainLevel? {
		if state != .completedSuccessfully { return nil }

		let imageAtIndex = images.filter { (_, image) in image.baseTimeContext.index == baseTimeIndex }.first?.1
		guard let key = imageAtIndex?.url.absoluteString else { return nil }
		return rainLevels[key]
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

	// this function run in not main queue when instance initialized
	private func calculateRainLevels() {
		state = .calculating

		rainLevels = [String : RainLevel]()

		images.forEach { (_, image) in
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
		sharedManager.remove(self)
		handler = nil
	}

// MARK: - ImageManagerNotification

	dynamic public func newImageFetched(notification: NSNotification) {
		guard let image = notification.userInfo?[ImageManager.Notification.object] as? Image else { return }

		// check this notification is for this object
		if images[image.url.absoluteString] != nil {
			if let error = notification.userInfo?[ImageManager.Notification.error] as? NSError {
				self.error = error
				state = .completedWithError
				return
			}

			checkAllImagesFetched()
		}
	}
}
