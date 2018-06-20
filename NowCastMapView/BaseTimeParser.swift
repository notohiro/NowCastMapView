//
//  BaseTimeParser.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

internal class BaseTimeParser: NSObject, XMLParserDelegate {
    internal var parsedArr = [String]()
    private var isBaseTimeElement: Bool = false

    internal func parserDidStartDocument(_ parser: XMLParser) {
	    isBaseTimeElement = false
    }

    internal func parser(_ parser: XMLParser,
                         didStartElement elementName: String,
                         namespaceURI: String?,
                         qualifiedName qName: String?,
                         attributes attributeDict: [String: String]) {
	    if elementName == "basetime" {
    	    isBaseTimeElement = true
	    }
    }

    internal func parser(_ parser: XMLParser, foundCharacters string: String) {
	    if isBaseTimeElement {
    	    parsedArr.append(string)
	    }
    }

    internal func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	    isBaseTimeElement = false
    }
}
