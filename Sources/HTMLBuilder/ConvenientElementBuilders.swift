//
//  ConvenientElementBuilders.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation

extension Element {
    
    public static func division(@NodeBuilder content: () throws -> [Node]) rethrows -> Self {
        try Self(name: "div", children: content)
    }
    public static func image(_ url: URL) -> Self {
        Self(name: "img", attributes: [.source: url.absoluteString])
    }
    public static func paragraph(@NodeBuilder content: () throws -> [Node]) rethrows -> Self {
        try Self(name: "p", children: content)
    }
    public static func button(_ title: String) -> Self {
        Self(name: "button", attributes: [.type: "button"]) {
            title
        }
    }
    public static func html(@NodeBuilder head: () throws -> [Node], @NodeBuilder body: () throws -> [Node]) rethrows -> Self {
        try Self(name: "html") {
            try Self(name: "head", children: head)
            try Self(name: "body", children: body)
        }
    }
    public static func cssLink(_ url: URL) -> Self {
        Self(name: "link", attributes: [.relationship: "stylesheet", .type: "text/css", .hypertextReference: url.absoluteString])
    }
    public static func javascript(_ script: String) -> Self {
        Self(name: "script", attributes: [.type: "application/javascript"]) {
            script
        }
    }
    public static func metadata(name: String, content: String) -> Self {
        Self.init(name: "meta", attributes: ["name": name, "content": content])
    }
    public static func metadata(httpEquivalent: String, content: String) -> Self {
        Self.init(name: "meta", attributes: ["http-equiv": httpEquivalent, "content": content])
    }
    public static func metadata(charset: String) -> Self {
        Self.init(name: "meta", attributes: ["charset": charset])
    }
}

extension Element.AttributeName {
    public static let identifier = Self(rawValue: "id")
    public static let `class` = Self(rawValue: "class")
    public static let hypertextReference = Self(rawValue: "href")
    public static let type = Self(rawValue: "type")
    public static let source = Self(rawValue: "src")
    public static let relationship = Self(rawValue: "rel")
}
