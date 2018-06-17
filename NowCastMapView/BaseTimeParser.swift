//
//  BaseTimeParser.swift
//  NowCastMapView
//
//  Created by Hiroshi Noto on 9/15/15.
//  Copyright © 2015 Hiroshi Noto. All rights reserved.
//

import Foundation

class BaseTimeParser: NSObject, XMLParserDelegate {
    var parsedArr = [String]()
    private var isBaseTimeElement: Bool = false

    func parserDidStartDocument(_ parser: XMLParser) {
	    isBaseTimeElement = false
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
	    if elementName == "basetime" {
    	    isBaseTimeElement = true
	    }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
	    if isBaseTimeElement {
    	    parsedArr.append(string)
	    }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	    isBaseTimeElement = false
    }
}
