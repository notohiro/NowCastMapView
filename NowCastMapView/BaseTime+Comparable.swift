//
//  BaseTime+Comparable.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/13/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

// MARK: - Comparable

extension BaseTime: Comparable {
	public static func == (lhs: BaseTime, rhs: BaseTime) -> Bool {
		guard let lhsBaseTimeDate = lhs.baseTimeDate(atIndex: 0) else { return false }
		guard let rhsBaseTimeDate = rhs.baseTimeDate(atIndex: 0) else { return false }

		if lhsBaseTimeDate.compare(rhsBaseTimeDate as Date) == .orderedSame {
			return true
		} else {
			return false
		}
	}

	public static func != (lhs: BaseTime, rhs: BaseTime) -> Bool {
		return !(lhs == rhs)
	}

	public static func < (lhs: BaseTime, rhs: BaseTime) -> Bool {
		guard let lhsBaseTimeDate = lhs.baseTimeDate(atIndex: 0) else { return false }
		guard let rhsBaseTimeDate = rhs.baseTimeDate(atIndex: 0) else { return false }

		if lhsBaseTimeDate.compare(rhsBaseTimeDate as Date) == .orderedAscending {
			return true
		} else {
			return false
		}
	}

	public static func > (lhs: BaseTime, rhs: BaseTime) -> Bool {
		return !(lhs < rhs)
	}
}
