//
//  NowCastBaseTimeParser.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

class NowCastBaseTimeParser: NSObject, NSXMLParserDelegate {
	var parsedArr = [String]()
	private var isBaseTimeElement: Bool = false

	func parserDidStartDocument(parser: NSXMLParser) {
		self.isBaseTimeElement = false
	}

	func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		if elementName == "basetime" {
			self.isBaseTimeElement = true
		}
	}

	func parser(parser: NSXMLParser, foundCharacters string: String) {
		if self.isBaseTimeElement {
			self.parsedArr.append(string)
		}
	}

	func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		self.isBaseTimeElement = false
	}
}
