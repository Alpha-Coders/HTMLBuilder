//
//  ElementModifiers.swift
//  
//
//  Created by Antoine Palazzolo on 18/12/2020.
//

import Foundation

extension Element {
    public func identifier(_ identifier: String?) -> Self {
        return self.attributes {
            $0[.identifier] = identifier
        }
    }
    
    public func `class`(_ class: String?) -> Self {
        return self.attributes {
            $0[.class] = `class`
        }
    }
    
    public func attributes(body: (inout [AttributeName: AttributeValue]) -> Void) -> Self {
        var result = self
        body(&result.attributes)
        return result
    }
}
