//
//  StatusCodeType.swift
//  RxSwiftAPI
//
//  Created by Marek Kojder on 13.01.2017.
//

import Foundation

protocol StatusCodeType: Equatable {

    ///Raw value of status code
    var value: Int { get }

    ///Human readable description of status code value
    var description: String { get }

    /**
     Type initializer.

     - Parameter value: Status code raw value.

     Returns initialized object if given value fits to type, otherwise nil.
     */
    init?(_ value: Int)
}
