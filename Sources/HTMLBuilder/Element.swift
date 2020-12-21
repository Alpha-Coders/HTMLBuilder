//
//  Element.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation
import libxml2

public struct Element: Node {
    public var name: String
    public var attributes: [AttributeName: AttributeValue]
    public var children: [Node]
    
    public func asXMLNode() -> xmlNodePtr {
        guard let node = xmlNewNode(nil, self.name) else { fatalError("node allocation failed") }
        for (attrName, attrValue) in self.attributes.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            xmlNewProp(node, attrName.rawValue, attrValue)
        }
        for child in self.children {
            xmlAddChild(node, child.asXMLNode())
        }
        return node
    }
    public func isEqual(to other: Node) -> Bool {
        if let other = other as? Element {
            if self.name != other.name { return false }
            if self.attributes != other.attributes { return false }
            if self.children.count != other.children.count { return false }
            if zip(self.children, other.children).allSatisfy({ $0.0.isEqual(to: $0.1) }) == false { return false }
            return true
        }
        return false
    }
    
    public init(name: String, attributes: [AttributeName: AttributeValue], children: [Node]) {
        self.name = name
        self.attributes = attributes
        self.children = children
    }
    public init(name: String, attributes: [AttributeName: AttributeValue] = [:], @NodeBuilder children: () throws -> [Node]) rethrows {
        self.init(name: name, attributes: attributes, children: try children())
    }
    public init(name: String, attributes: [AttributeName: AttributeValue] = [:]) {
        self.init(name: name, attributes: attributes, children: [])
    }
}
extension Element {
    public struct AttributeName: RawRepresentable, Hashable, ExpressibleByStringLiteral {
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }
    }
    public typealias AttributeValue = String?
}
