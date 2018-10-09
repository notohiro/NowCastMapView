//
//  RGBA255.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/23.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit

public struct RGBA255 {
    public let red: Int
    public let green: Int
    public let blue: Int
    public let alpha: Int

    public init(red: Int, green: Int, blue: Int, alpha: Int) {
	    self.red = RGBA255.round(red)
	    self.green = RGBA255.round(green)
	    self.blue = RGBA255.round(blue)
	    self.alpha = RGBA255.round(alpha)
    }

    private static func round(_ value: Int) -> Int {
	    if value < 0 { return 0 }
	    if value > 255 { return 255 }
	    return value
    }
}

// MARK: - Hashable

extension RGBA255: Hashable {
    public var hashValue: Int {
	    return red + (green * 256) + (blue * 256 * 256) + (alpha * 256 * 256 * 256)
    }
}

// MARK: - Equatable

extension RGBA255: Equatable {
    public static func == (lhs: RGBA255, rhs: RGBA255) -> Bool {
	    return lhs.red == rhs.red && lhs.green == rhs.green && lhs.blue == rhs.blue && lhs.alpha == rhs.alpha ? true : false
    }
}
