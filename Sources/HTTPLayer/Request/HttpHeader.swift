//
//  HttpHeader.swift
//  SwiftAPI
//
//  Created by Marek Kojder on 23.01.2017.
//

import Foundation

struct HttpHeader {

    ///HTTP header field name.
    let name: String

    ///HTTP header field value.
    let value: String

    /**
     - Parameters:
       - name: String containing HTTP header field name.
       - value: String containing HTTP header field value.
     */
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension HttpHeader: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value)
    }

    public static func ==(lhs: HttpHeader, rhs: HttpHeader) -> Bool {
        return lhs.name == rhs.name &&
               lhs.value == rhs.value
    }
}
