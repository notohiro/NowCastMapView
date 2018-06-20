//
//  UIColor.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 2016/09/24.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    internal convenience init(rgba255: RGBA255) {
	    let red = CGFloat(Double(rgba255.red) / 255.0)
	    let green = CGFloat(Double(rgba255.green) / 255.0)
	    let blue = CGFloat(Double(rgba255.blue) / 255.0)
	    self.init(red: red, green: green, blue: blue, alpha: CGFloat(rgba255.alpha))
    }
}
