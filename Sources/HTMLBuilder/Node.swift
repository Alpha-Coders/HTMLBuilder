//
//  Node.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation
import libxml2

public protocol Node: XMLNodeConvertible {
    func renderHTML() -> String
    func isEqual(to other: Node) -> Bool
}
public protocol XMLNodeConvertible {
    func asXMLNode() -> xmlNodePtr
}

public extension Node {
    func renderHTML() -> String {
        let doc = htmlNewDocNoDtD(nil, nil)
        xmlDocSetRootElement(doc, self.asXMLNode())
        
        var result: UnsafeMutablePointer<xmlChar>? = nil
        var size: Int32 = 0
        htmlDocDumpMemoryFormat(doc, &result, &size, 0)
        xmlFreeDoc(doc)
        guard let stringResult = result.flatMap(String.init(xmlString:)) else {
            fatalError("invalid generated html data")
        }
        return stringResult.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    func isEqual(to other: Node?) -> Bool {
        if let other = other {
            return self.isEqual(to: other)
        }
        return false
    }
}

//temporary solution before swift 5.4 and array support in ResultBuilder
public struct ForEach<T> {
    var values: [T]
    var content: (T) -> Node
    public init(_ values: [T], content: @escaping (T) -> Node) {
        self.values = values
        self.content = content
    }
}

@_functionBuilder public struct NodeBuilder {
    public static func buildBlock() -> [Node] {
        return []
    }
    public static func buildExpression(_ node: Node) -> [Node] {
        return [node]
    }
    public static func buildExpression<T>(_ expression: ForEach<T>) -> [Node] {
        return expression.values.map(expression.content)
    }
    public static func buildExpression(_ expression: RawHTML) -> [Node] {
        return expression.nodes
    }
    public static func buildBlock(_ nodes: [Node]...) -> [Node] {
        return nodes.flatMap { $0 }
    }
    public static func buildOptional(_ nodes: [Node]?) -> [Node] {
        return nodes ?? []
    }
    public static func buildEither(first nodes: [Node]) -> [Node] {
        return nodes
    }
    public static func buildEither(second nodes: [Node]) -> [Node] {
        return nodes
    }
    public static func buildArray(_ nodes: [[Node]]) -> [Node] {
        return nodes.flatMap { $0 }
    }
}
