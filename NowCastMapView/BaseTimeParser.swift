//
//  BaseTimeParser.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

class BaseTimeParser: NSObject, NSXMLParserDelegate {
	var parsedArr = [String]()
	private var isBaseTimeElement: Bool = false

	func parserDidStartDocument(parser: NSXMLParser) {
		isBaseTimeElement = false
	}

	func parser(parser: NSXMLParser, didStartElement elementName: String,
	            namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		if elementName == "basetime" {
			isBaseTimeElement = true
		}
	}

	func parser(parser: NSXMLParser, foundCharacters string: String) {
		if isBaseTimeElement {
			parsedArr.append(string)
		}
	}

	func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		isBaseTimeElement = false
	}
}
