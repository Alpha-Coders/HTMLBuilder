//
//  RawHTML.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation
import libxml2

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
                var attributes: [Element.AttributeName: String?] = [:]
                var currentAttribute = child.withMemoryRebound(to: xmlElement.self, capacity: 1) { $0.pointee.attributes }
                while let attribute = currentAttribute {
                    if let attrName = String(xmlString: attribute.pointee.name) {
                        let content = attribute.pointee.children?.pointee.content
                        attributes[.init(rawValue: attrName)] = .some(content.flatMap(String.init(xmlString:)))
                    }
                    currentAttribute = UnsafeMutableRawPointer(attribute.pointee.next)?.bindMemory(to: xmlAttribute.self, capacity: 1)
                }
                let children = Self.nodes(from: child)
                result.append(Element(name: name, attributes: attributes, children: children))
            case XML_TEXT_NODE:
                if xmlIsBlankNode(child) > 0 { break }
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
