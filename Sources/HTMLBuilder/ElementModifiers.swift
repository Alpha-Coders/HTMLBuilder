//
//  ElementModifiers.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation

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
}
