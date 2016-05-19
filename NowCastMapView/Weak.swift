//
//  Weak.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2/16/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

public class Weak<T: AnyObject> {
	private weak var _value:T?

	public init(value: T) {
		_value = value
	}

	public func value() -> T? {
		return _value
	}
}
