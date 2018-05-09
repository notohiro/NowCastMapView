# NowCastMapView

[![Swift](https://img.shields.io/badge/Swift-4.1%2B-orange.svg)](https://swift.org)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/NowCastMapView.svg)](https://img.shields.io/cocoapods/v/NowCastMapView.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/NowCastMapView.svg?style=flat)](http://cocoapods.org/pods/NowCastMapView)
![license](https://cocoapod-badges.herokuapp.com/l/URWeatherView/badge.png)
[![Twitter](https://img.shields.io/badge/twitter-@notohiro-blue.svg?style=flat)](http://twitter.com/notohiro)

NowCastMapView is an library for [High-resolution Precipitation Nowcasts](http://www.jma.go.jp/en/highresorad/) provided by [Japan Meteorological Agency](http://www.jma.go.jp/jma/indexe.html) written in Swift

## Features

<img src="https://raw.githubusercontent.com/notohiro/NowCastMapView/master/ScreenShot.png" width="640">

- [x] Overlay Nowcasts Images on Apple Maps.
- [x] Obtain Precipitation for specific coordinate.

## Requirements

- iOS 8.0+
- Xcode 9.3+

## Installation

NowCastMapView is available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods

To install, simply add the following line to your `Podfile`:

> CocoaPods 0.39.0+ is required to build NowCastMapView.

```ruby
platform :ios, '11.0'
use_frameworks!

pod 'NowCastMapView'
```

### Carthage

To integrate NowCastMapView into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "notohiro/NowCastMapView"
```

Run `carthage update` to build the framework and drag the built `NowCastMapView.framework` into your Xcode project.

## Usage

See Example Application.

### NowCastMapView

Just put MapView as NowCastMapView into your StoryBoard.  
We provided NowCastMapViewController for general purpose, and of course,  you can use own custom ViewController for specific use case.  

### NowCastRainLevels

You can obtain precipitation of specific coordinate from just few lines.

## License

NowCastMapView is available under the MIT license. See the LICENSE file for more info.
