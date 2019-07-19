//
//  APIRequest.swift
//  RxSwiftAPI
//
//  Created by Marek Kojder on 16.12.2016.
//

import Foundation
import RxSwift

typealias HttpRequestCompletionHandler = SessionServiceCompletionHandler

final class RequestService: NSObject {

    private let fileManager: FileManager

    //MARK: - Handling multiple sessions
    private var activeSessions = [Configuration: SessionService]()

    ///Returns URLSession for given configuration. If session does not exist, it creates one.
    private func activeSession(for configuration: Configuration) -> SessionService {
        if let session = activeSessions[configuration] {
            if session.isValid {
                return session
            } else {
                activeSessions.removeValue(forKey: configuration)
            }
        }
        let service = SessionService(configuration: configuration)
        activeSessions[configuration] = service
        return service
    }

    //MARK: - Handling background sessions
    ///Keeps completion handler for background sessions.
    lazy var backgroundSessionCompletionHandler = [String : () -> Void]()

    //MARK: Initialization
    ///Initializes service with given file manager.
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    deinit {
        activeSessions.forEach { $0.value.invalidateAndCancel() }
    }
}

//MARK: - Managing requests
extension RequestService {

    /**
     Sends given HTTP request.

     - Parameters:
       - request: An HttpDataRequest object provides request-specific information such as the URL, HTTP method or body data.
       - configuration: RequestService.Configuration indicates request configuration.

     HttpDataRequest may run only with foreground configuration.
     */
    func sendHTTPRequest(_ request: HttpDataRequest, with configuration: Configuration = .foreground, progress: SessionServiceProgressHandler?, completion: @escaping HttpRequestCompletionHandler) {
        let session = activeSession(for: configuration)
        session.data(request: request.urlRequest, progress: progress, completion: completion)
    }

    /**
     Sends given HTTP request.

     - Parameters:
       - request: An HttpUploadRequest object provides request-specific information such as the URL, HTTP method or URL of the file to upload.
       - configuration: RequestService.Configuration indicates upload request configuration.
     */
    func sendHTTPRequest(_ request: HttpUploadRequest, with configuration: Configuration = .background, progress: SessionServiceProgressHandler?, completion: @escaping HttpRequestCompletionHandler) {
        let session = activeSession(for: configuration)
        session.upload(request: request.urlRequest, file: request.resourceUrl, progress: progress, completion: completion)
    }

    /**
     Sends given HTTP request.

     - Parameters:
       - request: An HttpUploadRequest object provides request-specific information such as the URL, HTTP method or URL of the place on disc for downloading file.
       - configuration: RequestService.Configuration indicates download request configuration.
     */
    func sendHTTPRequest(_ request: HttpDownloadRequest, with configuration: Configuration = .background, progress: SessionServiceProgressHandler?, completion: @escaping HttpRequestCompletionHandler) {
        let session = activeSession(for: configuration)
        session.download(request: request.urlRequest, progress: progress, completion: completion)
    }

    /**
     Temporarily suspends given HTTP request.

     - Parameter request: An HttpRequest to suspend.
     */
    func suspend(_ request: HttpRequest) {
        activeSessions.forEach{ $0.value.suspend(request.urlRequest) }
    }

    /**
     Resumes given HTTP request, if it is suspended.

     - Parameter request: An HttpRequest to resume.
     */
    @available(iOS 9.0, OSX 10.11, *)
    func resume(_ request: HttpRequest) {
        activeSessions.forEach{ $0.value.resume(request.urlRequest) }
    }

    /**
     Cancels given HTTP request.

     - Parameter request: An HttpRequest to cancel.
     */
    func cancel(_ request: HttpRequest) {
        activeSessions.forEach{ $0.value.cancel(request.urlRequest) }
    }

    ///Cancels all currently running HTTP requests.
    func cancelAllRequests() {
        activeSessions.forEach{ $0.value.cancelAllRequests() }
    }
}
