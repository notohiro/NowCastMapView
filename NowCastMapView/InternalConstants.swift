//
//  InternalConstants.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import AwesomeCache

// define coordinate of upper left and bottom right
internal let kNowCastOriginLatitude: Double =    61
internal let kNowCastOriginLongitude: Double =   100
internal let kNowCastTerminalLatitude: Double =  7
internal let kNowCastTerminalLongitude: Double = 170

// define priority of downloading
internal let kNowCastDownloadPriorityUrgent: Float =	1.0
internal let kNowCastDownloadPriorityHigh: Float =		0.8
internal let kNowCastDownloadPriorityDefault: Float =	0.6
internal let kNowCastDownloadPriorityLow: Float =		0.4
// cancel image request by cancelPrefetch()
internal let kNowCastDownloadPriorityPrefetchForward: Float =		0.2
internal let kNowCastDownloadPriorityPrefetchBackward: Float =		0.1

internal let kNowCastDownloadPriorityBaseTime =  kNowCastDownloadPriorityUrgent

let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())