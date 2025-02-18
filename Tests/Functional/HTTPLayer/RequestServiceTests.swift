//
//  RequestServiceTests.swift
//  RxSwiftAPI
//
//  Created by Marek Kojder on 04.01.2017.
//

import XCTest
@testable import RxSwiftAPI

class RequestServiceTests: XCTestCase {

    private var requestService: Http.Service!

    override func setUp() {
        super.setUp()

        requestService = Http.Service(fileManager: DefaultFileManager())
    }

    override func tearDown() {
        requestService = nil
        super.tearDown()
    }
}

extension RequestServiceTests {

    //MARK: - DataRequest tests
    func testHttpGetDataRequest() {
        let url = TestData.Url.root.appendingPathComponent("get")

        performTestDataRequest(url: url, method: .get)
    }

    func testHttpPostDataRequest() {
        let url = TestData.Url.root.appendingPathComponent("post")
        let body = jsonData(with: ["title": "test", "body": "post", "userId": 1] as [String : Any])

        performTestDataRequest(url: url, method: .post, body: body)
    }

    func testHttpPutDataRequest() {
        let url = TestData.Url.root.appendingPathComponent("put")
        let body = jsonData(with: ["id": 1, "title": "test", "body": "put", "userId": 1] as [String : Any])

        performTestDataRequest(url: url, method: .put, body: body)
    }

    func testHttpPatchDataRequest() {
        let url = TestData.Url.root.appendingPathComponent("patch")
        let body = jsonData(with: ["body": "patch"] as [String : Any])

        performTestDataRequest(url: url, method: .patch, body: body)
    }

    func testHttpDeleteDataRequest() {
        let url = TestData.Url.root.appendingPathComponent("delete")

        performTestDataRequest(url: url, method: .delete)
    }

    //MARK: UploadRequest tests
    func testHttpPostUploadRequest() {
        let url = TestData.Url.root.appendingPathComponent("post")
        let resourceUrl = TestData.Url.localFile

        performTestUploadRequest(url: url, method: .post, resourceUrl: resourceUrl)
    }

    func testHttpPutUploadRequest() {
        let url = TestData.Url.root.appendingPathComponent("put")
        let resourceUrl = TestData.Url.localFile

        performTestUploadRequest(url: url, method: .put, resourceUrl: resourceUrl)
    }

    func testHttpPatchUploadRequest() {
        let url = TestData.Url.root.appendingPathComponent("patch")
        let resourceUrl = TestData.Url.localFile

        performTestUploadRequest(url: url, method: .patch, resourceUrl: resourceUrl)
    }

    //MARK: DownloadRequest tests
    func testHttpDownloadRequest() {
        let fileUrl = TestData.Url.smallFile
        let destinationUrl = TestData.Url.fileDestination
        let responseExpectation = expectation(description: "Expect response from \(fileUrl)")
        var successPerformed = false
        var failurePerformed = false
        var responseError: NSError?
        let completion: Http.Service.CompletionHandler = { response, error in
            let message: String
            if let error = error {
                failurePerformed = true
                responseError = error as NSError?
                message = "failed with error: \(error.localizedDescription)."
            } else if let response = response {
                if let code = response.statusCode {
                    message = "finished with status code \(code)."
                } else {
                    message = "finished."
                }
                successPerformed = true
            } else {
                message = "finished without success or error."
            }
            print("--------------------")
            print("HttpDownloadRequest from URL \(fileUrl) \(message)")
            print("--------------------")
            responseExpectation.fulfill()
        }

        let request = Http.DownloadRequest(url: fileUrl, destinationUrl: destinationUrl)
        _ = try? requestService.send(request: request, with: .foreground, completion: completion)

        waitForExpectations(timeout: 300) { error in
            XCTAssertNil(error, "Download request test failed with error: \(error!.localizedDescription)")
            XCTAssertFalse(failurePerformed, "Download request finished with failure: \(responseError!.localizedDescription)")
            XCTAssertTrue(successPerformed)
        }
    }

    //MARK: Request managing tests
    func testHttpRequestCancel() {
        let fileUrl = TestData.Url.smallFile
        let destinationUrl = TestData.Url.fileDestination
        let responseExpectation = expectation(description: "Expect response from \(fileUrl)")
        var successPerformed = false
        var failurePerformed = false
        var responseError: NSError?
        let completion: Http.Service.CompletionHandler = { response, error in
            let message: String
            if let error = error {
                failurePerformed = true
                responseError = error as NSError?
                message = "failed with error: \(error.localizedDescription)."
            } else if let response = response {
                if let code = response.statusCode {
                    message = "finished with status code \(code)."
                } else {
                    message = "finished."
                }
                successPerformed = true
            } else {
                message = "finished without success or error."
            }
            print("--------------------")
            print("HttpDownloadRequest from URL \(fileUrl) \(message)")
            print("--------------------")
            responseExpectation.fulfill()
        }

        let request = Http.DownloadRequest(url: fileUrl, destinationUrl: destinationUrl)
        let task = try? requestService.send(request: request, with: .foreground, completion: completion)
        task?.cancel()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error, "Download request test failed with error: \(error!.localizedDescription)")
            XCTAssertTrue(failurePerformed)
            XCTAssertTrue(responseError?.domain == NSURLErrorDomain && responseError?.code == -999, "Resposne should finnish with cancel error!")
            XCTAssertFalse(successPerformed)
        }
    }

    func testHttpRequestCancelAll() {
        let fileUrl1 = TestData.Url.bigFile
        let fileUrl2 = TestData.Url.bigFile
        let destinationUrl = TestData.Url.fileDestination
        let responseExpectation = expectation(description: "Expect file")
        var failurePerformed = false
        var responseError: NSError?
        let completion: Http.Service.CompletionHandler = { response, error in
            let message: String
            if let error = error {
                let firstError = !failurePerformed
                failurePerformed = true
                responseError = error as NSError?
                message = "failed with error: \(error.localizedDescription)."
                if firstError {
                    responseExpectation.fulfill()
                }
            } else if let response = response {
                if let code = response.statusCode {
                    message = "finished with status code \(code)."
                } else {
                    message = "finished."
                }
            } else {
                message = "finished without success or error."
            }
            print("--------------------")
            print("HttpDownloadRequest from URL \(fileUrl2) \(message)")
            print("--------------------")
        }
        
        let request1 = Http.DownloadRequest(url: fileUrl1, destinationUrl: destinationUrl)
        let request2 = Http.DownloadRequest(url: fileUrl2, destinationUrl: destinationUrl)

        _ = try? requestService.send(request: request1, with: .foreground, completion: completion)
        _ = try? requestService.send(request: request2, with: .foreground, completion: completion)
        _ = try? requestService.send(request: request1, with: .foreground, completion: completion)
        _ = try? requestService.send(request: request2, with: .foreground, completion: completion)
        requestService.cancelAllRequests()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error, "Download request test failed with error: \(error!.localizedDescription)")
            XCTAssertTrue(failurePerformed)
            XCTAssertNotNil(responseError, "Resposne should finnish with error!")
        }
    }

    func testSuspendAndResume() {
        let url = TestData.Url.root.appendingPathComponent("get")
        let method = Http.Method.get
        let responseExpectation = expectation(description: "Expect response from \(url)")
        var successPerformed = false
        var failurePerformed = false
        var responseError: Error?
        let completion: Http.Service.CompletionHandler = { response, error in
            let message: String
            if let error = error {
                failurePerformed = true
                responseError = error
                message = "failed with error: \(error.localizedDescription)."
            } else if let response = response {
                if let code = response.statusCode {
                    message = "finished with status code \(code)."
                } else {
                    message = "finished."
                }
                successPerformed = true
            } else {
                message = "finished without success or error."
            }
            print("--------------------")
            print("\(method.rawValue) request to URL \(url) \(message)")
            print("--------------------")
            responseExpectation.fulfill()
        }

        let request = Http.DataRequest(url: url, method: method)
        let task = try? requestService.send(request: request, with: .foreground, completion: completion)
        task?.suspend()
        task?.resume()

        waitForExpectations(timeout: 30) { error in
            XCTAssertNil(error, "\(method.rawValue) request test failed with error: \(error!.localizedDescription)")
            XCTAssertFalse(failurePerformed, "\(method.rawValue) request finished with failure: \(responseError!.localizedDescription)")
            XCTAssertTrue(successPerformed)
        }
    }
}


extension RequestServiceTests {

    ///Prepare JSON Data object
    fileprivate func jsonData(with dictionary: [String : Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }

    ///Perform test of data request with given parameters
    fileprivate func performTestDataRequest(url: URL, method: Http.Method, body: Data? = nil, file: StaticString = #file, line: UInt = #line) {
        let responseExpectation = expectation(description: "Expect response from \(url)")
        var successPerformed = false
        var failurePerformed = false
        var responseError: Error?
        let completion: Http.Service.CompletionHandler = { response, error in
            let message: String
            if let error = error {
                failurePerformed = true
                responseError = error
                message = "failed with error: \(error.localizedDescription)."
            } else if let response = response {
                if let code = response.statusCode {
                    message = "finished with status code \(code)."
                } else {
                    message = "finished."
                }
                successPerformed = true
            } else {
                message = "finished without success or error."
            }
            print("--------------------")
            print("\(method.rawValue) request to URL \(url) \(message)")
            print("--------------------")
            responseExpectation.fulfill()
        }

        let request = Http.DataRequest(url: url, method: method, body: body)
        _ = try? requestService.send(request: request, with: .foreground, completion: completion)

        waitForExpectations(timeout: 30) { error in
            XCTAssertNil(error, "\(method.rawValue) request test failed with error: \(error!.localizedDescription)", file: file, line: line)
            XCTAssertFalse(failurePerformed, "\(method.rawValue) request finished with failure: \(responseError!.localizedDescription)", file: file, line: line)
            XCTAssertTrue(successPerformed, file: file, line: line)
        }
    }

    ///Perform test of upload request with given parameters
    fileprivate func performTestUploadRequest(url: URL, method: Http.Method, resourceUrl: URL, file: StaticString = #file, line: UInt = #line) {
        let responseExpectation = expectation(description: "Expect response from \(url)")
        var successPerformed = false
        var failurePerformed = false
        var responseError: Error?
        let completion: Http.Service.CompletionHandler = { response, error in
            let message: String
            if let error = error {
                failurePerformed = true
                responseError = error
                message = "failed with error: \(error.localizedDescription)."
            } else if let response = response {
                if let code = response.statusCode {
                    message = "finished with status code \(code)."
                } else {
                    message = "finished."
                }
                successPerformed = true
            } else {
                message = "finished without success or error."
            }
            print("--------------------")
            print("\(method.rawValue) request to URL \(url) \(message)")
            print("--------------------")
            responseExpectation.fulfill()
        }

        let request = Http.UploadRequest(url: url, method: method, resourceUrl: resourceUrl)
        DispatchQueue.global(qos: .utility).async {
            _ = try? self.requestService.send(request: request, with: .foreground, completion: completion)
        }

        waitForExpectations(timeout: 300) { error in
            XCTAssertNil(error, "\(method.rawValue) request test failed with error: \(error!.localizedDescription)", file: file, line: line)
            XCTAssertFalse(failurePerformed, "\(method.rawValue) request finished with failure: \(responseError!.localizedDescription)", file: file, line: line)
            XCTAssertTrue(successPerformed, file: file, line: line)
        }
    }
}
