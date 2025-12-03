//
//  NetworkAbilityTests.swift
//  
//
//  Created by 黄磊 on 2022/11/16.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import XCTest
import Ability
@testable import NetworkAbility

final class NetworkAbilityTests: XCTestCase {
    let host = "https://httpbin.miejoy.com:4443"
    let timeout: TimeInterval = 10
    
    func testNetworkHeaders() {
        var headers = NetworkHeaders([("key1", "value1"), ("key2", "value2")])
        XCTAssertEqual(headers.headers.count, 2)
        XCTAssertEqual(headers["key1"].count, 1)
        XCTAssertEqual(headers["key1"].first, "value1")
        XCTAssertEqual(headers["key2"].count, 1)
        XCTAssertEqual(headers["key2"].first, "value2")
        
        // 添加新 key
        headers.add(name: "key3", value: "value3")
        XCTAssertEqual(headers.headers.count, 3)
        XCTAssertEqual(headers["key1"].first, "value1")
        XCTAssertEqual(headers["key2"].first, "value2")
        XCTAssertEqual(headers["key3"].count, 1)
        XCTAssertEqual(headers["key3"].first, "value3")
        
        // 添加重复 key
        headers.add(name: "key1", value: "value11")
        XCTAssertEqual(headers.headers.count, 4)
        XCTAssertEqual(headers["key1"].count, 2)
        XCTAssertEqual(headers["key1"], ["value1", "value11"])
    
        // 添加并移除 key
        headers.replaceOrAdd(name: "key1", value: "value111")
        XCTAssertEqual(headers.headers.count, 3)
        XCTAssertEqual(headers["key1"].count, 1)
        XCTAssertEqual(headers["key1"].first, "value111")
    }
    
    func testNetworkAbility() {
        let network = Ability.network
        
        XCTAssertTrue(network is DefaultHTTPDriver)
    }
    
    func testGetRequest() {
        
        let urlString = host + "/get?"
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The GET request should succeed")
        
        Ability.network.request(URL(string:urlString)!).completion { result in
            response = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        XCTAssertNotNil(response)
        XCTAssertNotNil(response!.value)
        XCTAssertNil(response!.error)
    }
    
    func testAsyncGetRequest() async throws {
        let urlString = host + "/get?"
        
        let response: [String:Any] = try await Ability.network.request(URL(string:urlString)!)
        
        XCTAssert(!response.isEmpty)
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
        
        Ability.network.request(URL(string:urlString)!, .set, body: EncodeDic(postData), header: nil)
            .map { $0 }
            .completionOnce { (result:Result<ResponseObject, Error>) in
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
    
    func testAsyncPostRequestDecodeToObject() async throws {
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
        
        let response: ResponseObject = try await Ability.network.request(URL(string:urlString)!, .set, body: EncodeDic(postData), header: nil)
        
        XCTAssertEqual(response.json.test, paramValue)
    }
    
    func testPostRequest() {
        
        let urlString = host + "/post"
        let paramKey = "test"
        let paramValue = "1"
        let postData = [paramKey:paramValue]
        var response: Result<[String:Any], Error>? = nil
        let expectation = self.expectation(description: "The Post request should succeed")
        
        Ability.network.request(URL(string:urlString)!, method: .set, body: EncodeDic(postData)).completion { (result) in
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
}
