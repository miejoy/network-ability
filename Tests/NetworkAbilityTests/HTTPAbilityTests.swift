//
//  HTTPAbilityTests.swift
//  
//
//  Created by 黄磊 on 2022/11/16.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import XCTest
import Ability
import Combine
@testable import NetworkAbility

final class HTTPAbilityTests: XCTestCase {
    let host = "https://httpbin.miejoy.com:4443"
    let timeout: TimeInterval = 10
    let tmpUrl : URL = {
        let fileManager = FileManager.default
        let aUrl = fileManager.temporaryDirectory.appendingPathComponent("Network")
        if !fileManager.fileExists(atPath: aUrl.path) {
            try? fileManager.createDirectory(at: aUrl, withIntermediateDirectories: true, attributes: nil)
        }
        return aUrl
    }()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        try? FileManager.default.removeItem(at: tmpUrl)
    }
    
    // MARK: - Test

    func testGetRequest() {
        
        let urlString = host + "/get?"
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The GET request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!).completion { result in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNotNil(response!.value)
        XCTAssertNil(response!.error)
    }
    
    func testGetRequestHeader() {
        
        let paramKey = "Test"
        let paramValue = "1"
        let urlString = host + "/get"
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The GET request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, header: [paramKey:paramValue]).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        
        XCTAssertEqual((value!["headers"] as! [String:String])[paramKey], paramValue)
        
    }
    
    func testGetJsonRequest() {
        
        let paramKey = "test"
        let paramValue = "1"
        let urlString = host + "/get?" + paramKey + "=" + paramValue
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The GET request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        
        XCTAssertEqual((value!["args"] as! [String:String])[paramKey], paramValue)
    }

    func testGetTextRequest() {
        
        let paramKey = "test"
        let paramValue = "1"
        let urlString = host + "/get?" + paramKey + "=" + paramValue
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The GET request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
        
        XCTAssertEqual((value!["args"] as! [String:String])[paramKey], paramValue)
    }
    
    func testGetRequestDecodeToObject() {
        
        struct ResponseObject: Decodable {
            let args: [String:String]
            let headers: [String: String]
            let origin: String
            let url: String
        }
        
        let urlString = host + "/get"
        let paramKey = "test"
        let paramValue = "1"
        let postData = [paramKey:paramValue]
        var response: Result<ResponseObject, Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, formData: .dic(postData), header: nil).completion { (result:Result<ResponseObject, Error>) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
                
        XCTAssertEqual(value!.args[paramKey], paramValue)
    }
    
    
    func testPostRequest() {
        
        let urlString = host + "/post"
        let paramKey = "test"
        let paramValue = "1"
        let postData = [paramKey:paramValue]
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, method: .POST, body: EncodeDic(postData)).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
        
        XCTAssertEqual((value!["json"] as! [String:String])[paramKey], paramValue)
    }
    
    func testPostEncodableRequest() {
        
        let urlString = host + "/post"
        let paramKey = "test"
        let paramValue = "1"
        struct PostData: Encodable {
            var test: String
        }
        let postData = PostData(test: paramValue)
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, method: .POST, body: postData).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
        
        XCTAssertEqual((value!["json"] as! [String:String])[paramKey], paramValue)
    }
    
    func testPostRequestHeader() {
        let urlString = host + "/post"
        let paramKey = "Test"
        let paramValue = "1"
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, method: .POST, header:[paramKey:paramValue]).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
        
        XCTAssertEqual((value!["headers"] as! [String:String])[paramKey], paramValue)
    }
    
    
    func testPostRequestDecodeToObject() {
        
        struct ResponseObject : Decodable {
            
            struct TestObject : Decodable {
                var test : String
            }
            var json : TestObject
        }
        
        let urlString = host + "/post"
        let paramKey = "test"
        let paramValue = "1"
        let postData = [paramKey:paramValue]
        var response: Result<ResponseObject, Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, .POST, body: EncodeDic(postData), header: nil).completion { (result:Result<ResponseObject, Error>) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
                
        XCTAssertEqual(value!.json.test, paramValue)
    }
    
    func testPostRequestDecodeToAny() {
        let urlString = host + "/post"
        let paramKey = "test"
        let paramValue = "1"
        let postData = [paramKey:paramValue]
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, method: .POST, body: EncodeDic(postData), header: nil).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
                
        XCTAssertEqual((value!["json"] as! [String:String])[paramKey], paramValue)
    }
    
    func testFormPostRequest() {
        
        let urlString = host + "/post"
        let paramKey = "test"
        let paramValue = "1"
        let postData = [paramKey:paramValue]
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, method: .POST, formData: .dic(postData)).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
        
        XCTAssertEqual((value!["form"] as! [String:String])[paramKey], paramValue)
    }
    
    func testEncodeFormPostRequest() {
        
        let urlString = host + "/post"
        let paramKey = "test"
        let paramValue = "1"
        struct FormData: Encodable {
            var test: String
        }
        let postData = FormData(test: paramValue)
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.http.httpRequest(URL(string:urlString)!, method: .POST, formData: .model(postData)).completion { (result) in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNil(response!.error)
        
        let value = response!.value
        XCTAssertNotNil(value)
        
        XCTAssertEqual((value!["form"] as! [String:String])[paramKey], paramValue)
    }
}

struct EncodeDic: Encodable {
    var dic: [String:Any]
    
    init(_ dic: [String : Any]) {
        self.dic = dic
    }
    
    struct AnyCodingKey: CodingKey {
        var stringValue: String
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? = nil
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try dic.forEach { (key: String, value: Any) in
            if let data = value as? Codable {
                try container.encode(data, forKey: .init(stringValue: key))
            } else if let subDic = value as? [String:Any] {
                try container.encode(EncodeDic(subDic), forKey: .init(stringValue: key))
            } else if let arr = value as? [[String:Any]] {
                try container.encode(arr.map(EncodeDic.init), forKey: .init(stringValue: key))
            }
        }
    }
}
