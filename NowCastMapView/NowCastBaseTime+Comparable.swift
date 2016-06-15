//
//  NowCastBaseTime+Comparable.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/13/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

public func ==(lhs: NowCastBaseTime, rhs: NowCastBaseTime) -> Bool {
	guard let lhsBaseTimeDate = lhs.baseTimeDate(atIndex: 0) else { return false }
	guard let rhsBaseTimeDate = rhs.baseTimeDate(atIndex: 0) else { return false }

	if lhsBaseTimeDate.compare(rhsBaseTimeDate) == .OrderedSame { return true }
	else { return false }
}

public func ==(lhs: NowCastBaseTime?, rhs: NowCastBaseTime) -> Bool {
	guard let lhs = lhs else { return false }

	return lhs == rhs
}

public func ==(lhs: NowCastBaseTime, rhs: NowCastBaseTime?) -> Bool {
	guard let rhs = rhs else { return false }

	return lhs == rhs
}

public func ==(lhs: NowCastBaseTime?, rhs: NowCastBaseTime?) -> Bool {
	guard let lhs = lhs else { return false }
	guard let rhs = rhs else { return false }

	return lhs == rhs
}

public func !=(lhs: NowCastBaseTime, rhs: NowCastBaseTime) -> Bool {
	guard let lhsBaseTimeDate = lhs.baseTimeDate(atIndex: 0) else { return true }
	guard let rhsBaseTimeDate = rhs.baseTimeDate(atIndex: 0) else { return true }

	if lhsBaseTimeDate.compare(rhsBaseTimeDate) != .OrderedSame { return true }
	else { return false }
}

public func !=(lhs: NowCastBaseTime?, rhs: NowCastBaseTime) -> Bool {
	guard let lhs = lhs else { return true }

	return lhs != rhs
}

public func !=(lhs: NowCastBaseTime, rhs: NowCastBaseTime?) -> Bool {
	guard let rhs = rhs else { return true }

	return lhs != rhs
}

public func !=(lhs: NowCastBaseTime?, rhs: NowCastBaseTime?) -> Bool {
	guard let lhs = lhs else { return true }
	guard let rhs = rhs else { return true }

	return lhs != rhs
}

public func <(lhs: NowCastBaseTime, rhs: NowCastBaseTime) -> Bool {
	guard let lhsBaseTimeDate = lhs.baseTimeDate(atIndex: 0) else { return false }
	guard let rhsBaseTimeDate = rhs.baseTimeDate(atIndex: 0) else { return false }

	if lhsBaseTimeDate.compare(rhsBaseTimeDate) == .OrderedAscending { return true }
	else { return false }
}