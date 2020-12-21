//
//  File.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation
import libxml2

extension String {
    init?(xmlString: UnsafeMutablePointer<xmlChar>) {
        self.init(cString: UnsafePointer(xmlString))
    }
    init?(xmlString: UnsafePointer<xmlChar>) {
        let pointer = UnsafeRawPointer(xmlString).assumingMemoryBound(to: CChar.self)
        self.init(cString: pointer, encoding: .utf8)
    }
}
