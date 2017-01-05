//
//  APIRequest.swift
//  SwiftAPI
//
//  Created by Marek Kojder on 16.12.2016.
//  Copyright © 2016 XSolve. All rights reserved.
//

import Foundation

final class RequestService: NSObject {

    //MARK: - Handling multiple tasks
    private var currentTasks = [URLSessionTask: (HttpRequest, HttpResponse?)]()

    ///Sets request for current task
    func setCurrent(_ request: HttpRequest, for task: URLSessionTask) {
        currentTasks[task] = (request, nil)
    }

    ///Sets response for current task but only when request already exists
    fileprivate func setCurrent(_ response: HttpResponse, for task: URLSessionTask) -> Bool {
        guard var request = currentTasks[task] else {
            print("Cannod add response when there is no request!")
            return false
        }
        request.1 = response
        currentTasks[task] = request
        return true
    }

    ///Returns request for currently running task if exists.
    fileprivate func currentRequest(for task: URLSessionTask) -> HttpRequest? {
        return currentTasks[task]?.0
    }

    ///Returns response for currently running task if exists.
    fileprivate func currentResponse(for task: URLSessionTask) -> HttpResponse? {
        return currentTasks[task]?.1
    }

    ///Returns request and response for currently running task if exists.
    fileprivate func currentRequestAndResponse(for task: URLSessionTask) -> (HttpRequest, HttpResponse?)? {
        return currentTasks[task]
    }

    ///Returns all currently running task with given request.
    fileprivate func currentTasks(for request: HttpRequest) -> [URLSessionTask] {
        return currentTasks.filter{ return $0.1.0 == request }.flatMap({ return $0.0 })
    }

    ///Removes given task from queue.
    fileprivate func removeCurrent(_ task: URLSessionTask) {
        currentTasks.removeValue(forKey: task)

        //If there is no working task, we need to invalidate all sessions to break strong reference with delegate
        if currentTasks.isEmpty {
            for (_, session) in currentSessions {
                session.finishTasksAndInvalidate()
            }
            //After invalidation, session objects cannot be reused, so we can remove all sessions.
            currentSessions.removeAll()
        }
    }

    ///Removes all tasks from queue.
    fileprivate func removeAllTasks() {
        currentTasks.removeAll()

        //If there is no working task, we need to invalidate all sessions to break strong reference with delegate
        for (_, session) in currentSessions {
            session.invalidateAndCancel()
        }
        //After invalidation, session objects cannot be reused, so we can remove all sessions.
        currentSessions.removeAll()
    }


    //MARK: - Handling multiple sessions
    private var currentSessions = [RequestServiceConfiguration : URLSession]()

    ///Returns URLSession for given configuration. If session does not exist, it creates one.
    fileprivate func currentSession(for configuration: RequestServiceConfiguration) -> URLSession {
        if let session = currentSessions[configuration] {
            return session
        }
        let session = URLSession(configuration: configuration.urlSessionConfiguration, delegate: self, delegateQueue: nil)
        currentSessions[configuration] = session
        return session
    }
}

//MARK: - Managing requests
extension RequestService {
    /**
     Sends given HTTP request.

     - Parameters:
       - request: An HttpDataRequest object provides request-specific information such as the URL, HTTP method or body data.
       - configuration: RequestServiceConfiguration indicates if request should be sent in foreground or background.
     */
    func sendHTTPRequest(_ request: HttpDataRequest, with configuration: RequestServiceConfiguration = .foreground) {
        let session = currentSession(for: configuration)
        let task = session.dataTask(with: request.urlRequest)
        setCurrent(request, for: task)
        task.resume()
    }

    /**
     Sends given HTTP request.

     - Parameters:
       - request: An HttpUploadRequest object provides request-specific information such as the URL, HTTP method or URL of the file to upload.
       - configuration: RequestServiceConfiguration indicates if request should be sent in foreground or background.
     */
    func sendHTTPRequest(_ request: HttpUploadRequest, with configuration: RequestServiceConfiguration = .background) {
        let session = currentSession(for: configuration)
        let task = session.uploadTask(with: request.urlRequest, fromFile: request.resourceUrl)
        setCurrent(request, for: task)
        task.resume()
    }

    /**
     Sends given HTTP request.

     - Parameters:
       - request: An HttpUploadRequest object provides request-specific information such as the URL, HTTP method or URL of the place on disc for downloading file.
       - configuration: RequestServiceConfiguration indicates if request should be sent in foreground or background.
     */
    func sendHTTPRequest(_ request: HttpDownloadRequest, with configuration: RequestServiceConfiguration = .background) {
        let session = currentSession(for: configuration)
        let task = session.downloadTask(with: request.urlRequest)
        setCurrent(request, for: task)
        task.resume()
    }

    /**
     Temporarily suspends given HTTP request.

     - Parameter request: An HttpUploadRequest to suspend.
     */
    func suspend(_ request: HttpRequest) {
        for task in currentTasks(for: request) {
            task.suspend()
        }
        request.progress?.pause()
    }

    /**
     Resumes given HTTP request, if it is suspended.

     - Parameter request: An HttpUploadRequest to resume.
     */
    func resume(_ request: HttpRequest) {
        for task in currentTasks(for: request) {
            task.resume()
        }
        if #available(iOS 9.0, *) {
            request.progress?.resume()
        } else {
            //TODO: Fallback on earlier versions
        }
    }

    /**
     Cancels given HTTP request.

     - Parameter request: An HttpUploadRequest to cancel.
     */
    func cancel(_ request: HttpRequest) {
        for task in currentTasks(for: request) {
            task.cancel()
        }
        request.progress?.cancel()
    }

    ///Cancels all currently running HTTP requests.
    func cancelAllRequests() {
        removeAllTasks()
    }
}

extension RequestService: URLSessionDelegate {

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        //Informs that finishTasksAndInvalidate() or invalidateAndCancel() method was call on session object.
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    }
}


extension RequestService: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let request = currentRequest(for: task) else {
            return
        }
        request.progress?.totalUnitCount = totalBytesExpectedToSend
        request.progress?.completedUnitCount = totalBytesSent
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let (request, response) = currentRequestAndResponse(for: task) else {
            return
        }
        if let error = error {
            //Action is running other thread to not block delegate.
            DispatchQueue.global(qos: .background).async {
                request.failureAction?.perform(with: error)
            }
        } else {
            //Action is running other thread to not block delegate.
            DispatchQueue.global(qos: .background).async {
                request.successAction?.perform(with: response)
            }
        }
        removeCurrent(task)
    }
}

extension RequestService: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        var httpResponse: HttpResponse
        if let resp = currentResponse(for: dataTask) {
            httpResponse = resp
            httpResponse.update(with: response)
        } else {
            httpResponse = HttpResponse(urlResponse: response)
        }

        if setCurrent(httpResponse, for: dataTask) {
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let response = currentResponse(for: dataTask) else {
            return
        }
        response.appendBody(data)
    }
}

extension RequestService: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let request = currentRequest(for: downloadTask) else {
            return
        }
        request.progress?.totalUnitCount = totalBytesExpectedToWrite
        request.progress?.completedUnitCount = totalBytesWritten
    }
}
