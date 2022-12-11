//
//  DefaultHTTPDriver.swift
//  
//
//  Created by 黄磊 on 2022/11/16.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine
import AutoConfig

/// 默认 HTTP 能力驱动
public final class DefaultHTTPDriver: HTTPAbility {
    
    public var requestEncoder: NetworkRequestEncoder
    public var responseDecoder: NetworkResponseDecoder
    public var needResponseHeader: Bool
    
    public init(
        requestEncoder: NetworkRequestEncoder = JSONEncoder(),
        responseDecoder: NetworkResponseDecoder = JSONDecoder(),
        needResponseHeader: Bool = true
    ) {
        self.requestEncoder = requestEncoder
        self.responseDecoder = responseDecoder
        self.needResponseHeader = needResponseHeader
    }
    
    public func httpRequest<E:Encodable>(
        url: URL,
        method: HTTPMethod,
        formData: URLEncodeWrapper?,
        body: E?,
        header: NetworkHeaders?
    ) -> Future<(Data, NetworkHeaders), Error> {
        // 生成 Request
        return Future<(Data, NetworkHeaders), Error>.init { promise in
            guard let request = self.makeRequest(url: url, method: method, formData: formData, body: body, header: header) else {
                promise(.failure(URLError(.badURL)))
                return
            }
            
            // 创建任务
            let dataTask = URLSession.shared.dataTask(with: request) { (data, respose, error) in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                guard let data = data else {
                    promise(.failure(URLError(.badServerResponse)))
                    return
                }
                
                var headers = NetworkHeaders()
                if self.needResponseHeader, let httpResponse = respose as? HTTPURLResponse {
                    for aHeader in httpResponse.allHeaderFields {
                        headers.add(name: "\(aHeader.key)", value: "\(aHeader.value)")
                    }
                }
                promise(.success((data, headers)))
            }
            
            // 开始请求
            dataTask.resume()
        }
    }
    
    func makeRequest<E:Encodable>(
        url: URL,
        method: HTTPMethod,
        formData: URLEncodeWrapper?,
        body: E?,
        header: NetworkHeaders?
    ) -> URLRequest? {
        var url = url
        var header = header ?? .init()
        if method == .get {
            formData?.encode(into: &url)
        }
        
        // 创建 请求
        var request = URLRequest(url: url)
        request.httpMethod = method.description
                
        if method != .get {
            if let body = body {
                do {
                    let data = try requestEncoder.encode(body, headers: &header)
                    request.httpBody = data
                } catch {
                    print(error)
                    return nil
                }
            } else {
                formData?.encode(into: &request)
            }
        }
        
        // 添加头部
        for aHeader in header.headers {
            request.addValue(aHeader.1, forHTTPHeaderField: aHeader.0)
        }
        
        return request
    }
}
