//
//  BaseTimeModel.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

public protocol BaseTimeProvider {
    var fetchInterval: TimeInterval { get set }
    var current: BaseTime? { get }
}

public protocol BaseTimeModelDelegate: class {
    func baseTimeModel(_ model: BaseTimeModel, fetched baseTime: BaseTime?)
}

/**
An `BaseTimeModel` object lets you fetch the `BaseTime`.
*/
open class BaseTimeModel: BaseTimeProvider {
    internal enum Constants {
        // swiftlint:disable:next force_unwrapping
	    internal static let url = URL(string: "http://www.jma.go.jp/jp/highresorad/highresorad_tile/tile_basetime.xml")!
	    internal static let fts = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    }

    open weak var delegate: BaseTimeModelDelegate?

    private let session = URLSession(configuration: URLSessionConfiguration.default)

    private var fetching = false

    private var fetchTimer: Timer?

    /// immediately fetch + interval
    open var fetchInterval: TimeInterval = 0 { // 0 means will never check automatically
	    didSet {
    	    objc_sync_enter(self)
    	    fetchTimer?.invalidate()

    	    if fetchInterval != 0 {
                let fetchTimer = Timer(timeInterval: fetchInterval,
                                       target: self,
                                       selector: #selector(BaseTimeModel.fetch),
                                       userInfo: nil,
                                       repeats: true)
	    	    RunLoop.main.add(fetchTimer, forMode: .commonModes)
	    	    self.fetchTimer = fetchTimer
	    	    fetch()
    	    }
    	    objc_sync_exit(self)
	    }
    }

    open internal(set) var current: BaseTime? {
	    didSet {
    	    delegate?.baseTimeModel(self, fetched: current)
	    }
    }

    public init() { }

    @objc
    open func fetch() {
	    objc_sync_enter(self)
	    if fetching {
    	    return
	    } else {
    	    fetching = true
	    }
	    objc_sync_exit(self)

	    let task = session.dataTask(with: Constants.url) { [unowned self] data, _, error in
    	    if error != nil { // do something?
    	    } else {
	    	    let baseTime = data.flatMap { BaseTime(baseTimeData: $0) }

	    	    if self.current == nil, let baseTime = baseTime {
    	    	    self.current = baseTime
	    	    } else if let current = self.current, let baseTime = baseTime, current < baseTime {
    	    	    self.current = baseTime
	    	    }
    	    }

    	    self.fetching = false
	    }
	    task.priority = URLSessionTask.highPriority
	    task.resume()
    }
}
