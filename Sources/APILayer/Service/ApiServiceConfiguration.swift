//
//  ApiServiceConfiguration.swift
//  RxSwiftAPI
//
//  Created by Marek Kojder on 05.06.2018.
//

import Foundation

public extension Api.Service {

    typealias CachePolicy = NSURLRequest.CachePolicy
    typealias CookieAcceptPolicy = HTTPCookie.AcceptPolicy
    typealias CookieStorage = HTTPCookieStorage

    ///Enum containing most common behaviors and policies for requests.
    enum Configuration {
        case foreground
        case ephemeral
        case background(String = defaultBackgroundId)
        case custom(URLSessionConfiguration)
    }
}

extension Api.Service.Configuration {

    ///Default background session configuration ID.
    public static let defaultBackgroundId = "RxSwiftAPI.ApiService.Configuration.background"

    ///*URLSessionConfiguration* object for current session.
    var requestServiceConfiguration: Http.Service.Configuration {
        switch self {
        case .foreground:
            return .foreground
        case .ephemeral:
            return .ephemeral
        case .background(let id):
            return .background(id)
        case .custom(let config):
            return .custom(config)
        }
    }
}

extension Api.Service.Configuration: Equatable {

    public static func ==(lhs: Api.Service.Configuration, rhs: Api.Service.Configuration) -> Bool {
        switch (lhs, rhs) {
        case (.foreground, .foreground),
             (.ephemeral, .ephemeral):
            return true
        case (.background(let lhsId), .background(let rhsId)):
            return lhsId == rhsId
        case (.custom(let lhsConfig), .custom(let rhsConfig)):
            return lhsConfig == rhsConfig
        default:
            return false
        }
    }
}

public extension Api.Service.Configuration {

    ///A Boolean value that determines whether connections should be made over a cellular network. The default value is true.
    var allowsCellularAccess: Bool {
        return requestServiceConfiguration.allowsCellularAccess
    }

    ///The timeout interval to use when waiting for additional data. The default value is 60.
    var timeoutForRequest: TimeInterval {
        return requestServiceConfiguration.timeoutForRequest
    }

    ///The maximum amount of time (in seconds) that a resource request should be allowed to take. The default value is 7 days.
    var timeoutForResource: TimeInterval {
        return requestServiceConfiguration.timeoutForResource
    }

    ///The maximum number of simultaneous connections to make to a given host. The default value is 6 in macOS, or 4 in iOS.
    var maximumConnectionsPerHost: Int {
        return requestServiceConfiguration.maximumConnectionsPerHost
    }

    ///A predefined constant that determines when to return a response from the cache. The default value is *.useProtocolCachePolicy*.
    var cachePolicy: Api.Service.CachePolicy {
        return requestServiceConfiguration.cachePolicy
    }

    ///A Boolean value that determines whether requests should contain cookies from the cookie store. The default value is true.
    var shouldSetCookies: Bool {
        return requestServiceConfiguration.shouldSetCookies
    }

    ///A policy constant that determines when cookies should be accepted. The default value is *.onlyFromMainDocumentDomain*.
    var cookieAcceptPolicy: Api.Service.CookieAcceptPolicy {
        return requestServiceConfiguration.cookieAcceptPolicy
    }

    ///The cookie store for storing cookies within this session. For *foreground* and *background* sessions, the default value is the shared cookie storage object.
    var cookieStorage: Api.Service.CookieStorage? {
        return requestServiceConfiguration.cookieStorage
    }
}
