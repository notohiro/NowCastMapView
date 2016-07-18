//
//  AppDelegate.swift
//  Example
//
//  Created by Hiroshi Noto on 1/26/16.
//  Copyright © 2016 Hiroshi Noto. All rights reserved.
//

import UIKit
import NowCastMapView

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		BaseTimeManager.sharedManager.fetch()
		BaseTimeManager.sharedManager.fetchInterval =  10
		ImageManager.sharedManager.removeAllCache()

        return true
    }

    func applicationWillResignActive(application: UIApplication) { }

    func applicationDidEnterBackground(application: UIApplication) {
		ImageManager.sharedManager.flushMemoryCache()
    }

    func applicationWillEnterForeground(application: UIApplication) { }

    func applicationDidBecomeActive(application: UIApplication) { }

    func applicationWillTerminate(application: UIApplication) { }
}
