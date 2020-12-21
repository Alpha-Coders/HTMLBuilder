//
//  StringNode.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation
import libxml2

extension String: Node {
    public func asXMLNode() -> xmlNodePtr {
        guard let node = xmlNewText(self) else { fatalError("node allocation failed") }
        return node
    }
    public func isEqual(to other: Node) -> Bool {
        return self == (other as? String)
    }
}
