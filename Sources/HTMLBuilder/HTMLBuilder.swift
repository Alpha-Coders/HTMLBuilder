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
        guard let resultData = result.map({ Data(bytesNoCopy: $0, count: Int(size), deallocator: .custom({ pt, _ in xmlFree(pt) })) }) else {
            fatalError("")
        }
        return String(data: resultData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    func isEqual(to other: Node?) -> Bool {
        if let other = other {
            return self.isEqual(to: other)
        }
        return false
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

    public init(name: String, attributes: [AttributeName: String], children: [Node]) {
        self.name = name
        self.attributes = attributes
        self.children = children
    }
    public init(name: String, attributes: [AttributeName: String] = [:], @NodeBuilder children: () throws -> [Node]) rethrows {
        self.init(name: name, attributes: attributes, children: try children())
    }
    public init(name: String, attributes: [AttributeName: String] = [:]) {
        self.init(name: name, attributes: attributes, children: [])
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
        static let relationship = AttributeName(rawValue: "rel")


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
    public func isEqual(to other: Node) -> Bool {
        return self == (other as? String)
    }
}

public class RawHTML {
    enum Error: Swift.Error {
        case invalidHTML
    }
    private let document: htmlDocPtr
    public convenience init(_ rawValue: String) throws {
        try self.init(data: Data(rawValue.utf8), encoding: .utf8)
    }
    public init(data: Data, encoding: String.Encoding?) throws {
        
        let options = Int32(HTML_PARSE_RECOVER.rawValue | HTML_PARSE_NONET.rawValue | HTML_PARSE_NOERROR.rawValue | HTML_PARSE_NOWARNING.rawValue)
         
        let encodingValue = encoding.map { (encoding) -> String in
            switch encoding {
            case .utf8: return "UTF-8"
            default:
                fatalError("unsupported encoding")
            }
        }
        self.document = try data.withUnsafeBytes { buffer -> htmlDocPtr in
            let pointer = buffer.baseAddress?.assumingMemoryBound(to: Int8.self)
            if let doc = htmlReadMemory(pointer, Int32(buffer.count), nil, encodingValue, options) {
                return doc
            } else {
                throw Error.invalidHTML
            }
        }
        
    }
    
    public var nodes: [Node] {
        guard let root = xmlDocGetRootElement(self.document) else { return [] }
        guard let body = Self.enumerateChildren(of: root).first(where: { String(xmlString: $0.pointee.name) == "body" }) else { return [] }
        return Self.nodes(from: body)
    }
    private static func nodes(from parent: xmlNodePtr) -> [Node] {
        var result: [Node] = []
        for child in Self.enumerateChildren(of: parent) {
            switch child.pointee.type {
            case XML_ELEMENT_NODE:
                let name = String(xmlString: child.pointee.name) ?? ""
                var attributes: [Element.AttributeName: String] = [:]
                var currentAttribute = child.withMemoryRebound(to: xmlElement.self, capacity: 1) { $0.pointee.attributes }
                while let attribute = currentAttribute {
                    if let name = String(xmlString: attribute.pointee.name),
                       let content = attribute.withMemoryRebound(to: xmlNode.self, capacity: 1, { xmlNodeGetContent($0) }) {
                        attributes[.init(rawValue: name)] = String(xmlString: content)
                        xmlFree(content)
                    }
                    currentAttribute = currentAttribute?.pointee.nexth
                }
                let children = Self.nodes(from: child)
                result.append(Element(name: name, attributes: attributes, children: children))
            case XML_TEXT_NODE:
                let content = xmlNodeGetContent(child)
                guard let text = content.flatMap(String.init(xmlString:)) else { break }
                xmlFree(content)
                result.append(text)
            default: break
            }
        }
        return result
    }
    private static func enumerateChildren(of parent: xmlNodePtr) -> AnySequence<xmlNodePtr> {
        return AnySequence { () -> AnyIterator<xmlNodePtr> in
            var current = parent.pointee.children
            return AnyIterator {
                let result = current
                current = current?.pointee.next
                return result
            }
        }
    }
    
    deinit {
        xmlFreeDoc(self.document)
    }
}

private extension String {
    init?(xmlString: UnsafeMutablePointer<xmlChar>) {
        self.init(cString: UnsafePointer(xmlString))
    }
    init?(xmlString: UnsafePointer<xmlChar>) {
        let pointer = UnsafeRawPointer(xmlString).assumingMemoryBound(to: CChar.self)
        self.init(cString: pointer, encoding: .utf8)
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
