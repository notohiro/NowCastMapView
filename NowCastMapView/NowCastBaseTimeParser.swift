//
//  NowCastBaseTimeParser.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

internal class NowCastBaseTimeParser: NSObject, NSXMLParserDelegate {
	internal var parsedArr = [String]()
	private var isBaseTimeElement: Bool = false

	internal func parserDidStartDocument(parser: NSXMLParser) {
		self.isBaseTimeElement = false
	}

	internal func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		if elementName == "basetime" {
			self.isBaseTimeElement = true
		}
	}

	internal func parser(parser: NSXMLParser, foundCharacters string: String) {
		if self.isBaseTimeElement {
			self.parsedArr.append(string)
		}
	}

	internal func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		self.isBaseTimeElement = false
	}
}
