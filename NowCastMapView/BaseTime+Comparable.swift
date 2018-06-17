//
//  BaseTime+Comparable.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/13/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation

// MARK: - Hashable

extension BaseTime: Hashable {
    public var hashValue: Int {
	    let base: String = self[0]
	    return base.hashValue
    }
}

// MARK: - Equatable

extension BaseTime: Equatable {
    public static func == (lhs: BaseTime, rhs: BaseTime) -> Bool {
	    return lhs.hashValue == rhs.hashValue
    }

    public static func != (lhs: BaseTime, rhs: BaseTime) -> Bool {
	    return !(lhs == rhs)
    }
}

// MARK: - Comparable

extension BaseTime: Comparable {
    public static func < (lhs: BaseTime, rhs: BaseTime) -> Bool {
	    let lhsDate: Date = lhs[0]
	    let rhsDate: Date = rhs[0]

	    if lhsDate.compare(rhsDate) == .orderedAscending {
    	    return true
	    } else {
    	    return false
	    }
    }

    public static func <= (lhs: BaseTime, rhs: BaseTime) -> Bool {
	    if lhs == rhs { return true }
	    return lhs < rhs
    }

    public static func >= (lhs: BaseTime, rhs: BaseTime) -> Bool {
	    if lhs == rhs { return true }
	    return lhs > rhs
    }

    public static func > (lhs: BaseTime, rhs: BaseTime) -> Bool {
	    return !(lhs < rhs)
    }
}
