import Foundation
import libxml2

public protocol Node: XMLNodeConvertible {
    func renderHTML() -> String
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
        guard let resultData = result.map({ Data(bytesNoCopy: $0, count: Int(size), deallocator: .custom({ pt, _ in xmlFree(pt) })) }) else {
            fatalError("")
        }
        return String(data: resultData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

public struct Element: Node {
    public var name: String
    public var attributes: [AttributeName: String]
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

    public init(name: String, attributes: [AttributeName: String] = [:], @NodeBuilder children: () throws -> [Node]) rethrows {
        self.name = name
        self.attributes = attributes
        self.children = try children()
    }
    public init(name: String, attributes: [AttributeName: String] = [:]) {
        self.init(name: name, attributes: attributes, children: { return [] })
    }
}
extension Element {
    public struct AttributeName: RawRepresentable, Hashable, ExpressibleByStringLiteral {
        public var rawValue: String
        static let identifier = AttributeName(rawValue: "id")
        static let `class` = AttributeName(rawValue: "class")
        static let hypertextReference = AttributeName(rawValue: "href")
        static let type = AttributeName(rawValue: "type")
        static let source = AttributeName(rawValue: "src")
        static let relationship = AttributeName(rawValue: "ref")


        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }
    }
}

extension Element {
    public func identifier(_ identifier: String?) -> Self {
        var result = self
        result.attributes[.identifier] = identifier
        return result
    }
    
    public func `class`(_ class: String?) -> Self {
        var result = self
        result.attributes[.class] = `class`
        return result
    }
    
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

extension String: Node {
    public func asXMLNode() -> xmlNodePtr {
        guard let node = xmlNewText(self) else { fatalError("node allocation failed") }
        return node
    }
}

public struct RawHTML: Node {
    enum RawHTMLError: Error {
        case invalidHTML
        case noRootElement
    }
    var node: xmlNodePtr
    public init(_ rawValue: String) throws {
        let data = Data(rawValue.utf8)
        let doc = try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws -> xmlDocPtr in
            let options = Int32(HTML_PARSE_RECOVER.rawValue | HTML_PARSE_NONET.rawValue | HTML_PARSE_NOIMPLIED.rawValue)
            let pointer = buffer.baseAddress?.assumingMemoryBound(to: Int8.self)
            if let doc = htmlReadMemory(pointer, Int32(buffer.count), nil, "UTF-8", options) {
                return doc
            } else {
                throw RawHTMLError.invalidHTML
            }
        }
        guard let node = xmlDocGetRootElement(doc) else { throw RawHTMLError.noRootElement }
        self.node = node
    }
    public func asXMLNode() -> xmlNodePtr {
        return self.node
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
