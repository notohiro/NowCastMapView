//
//  Constants.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 6/20/15.
//  Copyright (c) 2015 Hiroshi Noto. All rights reserved.
//

import Foundation
import AwesomeCache

// define coordinate of upper left and bottom right
let NowCastOriginLatitude:		Double = 61
let NowCastOriginLongitude:		Double = 100
let NowCastTerminalLatitude:	Double = 7
let NowCastTerminalLongitude:	Double = 170

//// define priority of downloading
public let NowCastDownloadPriorityUrgent:	Float =	1.0
public let NowCastDownloadPriorityHigh:		Float =	0.8
public let NowCastDownloadPriorityDefault:	Float =	0.6
public let NowCastDownloadPriorityLow:		Float =	0.4

// cancel image request by cancelPrefetch()
public let NowCastDownloadPriorityPrefetchForward:	Float =	0.2
public let NowCastDownloadPriorityPrefetchBackward: Float =	0.1

let NowCastDownloadPriorityBaseTime =  NowCastDownloadPriorityUrgent

let imageSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
let baseTimeSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())