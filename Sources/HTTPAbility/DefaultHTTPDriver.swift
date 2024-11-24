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
import UniformTypeIdentifiers

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
    
    public func httpUpload(url: URL, files: [URL], filesKey: String, method: HTTPMethod, formData: URLEncodeWrapper?, header: NetworkHeaders?) async throws -> (data: Data, header: NetworkHeaders) {
        guard var request = self.makeRequest(url: url, method: method, formData: .none, body: Optional<String>.none, header: header) else {
            throw URLError(.badURL)
        }
        
        var multipart = MultipartRequest()
        formData?.encode(into: &multipart)
        
        if files.count == 1, let firstFile = files.first {
            // 单个文件
            let fileData = try Data(contentsOf: firstFile)
            multipart.add(key: filesKey, fileName: firstFile.lastPathComponent, fileMimeType: firstFile.mimeType(), fileData: fileData)
        } else {
            // 多个个文件
            try files.enumerated().forEach { (offset, fileUrl) in
                let fileData = try Data(contentsOf: fileUrl)
                multipart.add(key: filesKey + "[\(offset)]", fileName: fileUrl.lastPathComponent, fileMimeType: fileUrl.mimeType(), fileData: fileData)
            }
        }
        request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.httpBody
        
        let (data, respose) = try await URLSession.shared.data(for: request)
        var headers = NetworkHeaders()
        if self.needResponseHeader, let httpResponse = respose as? HTTPURLResponse {
            for aHeader in httpResponse.allHeaderFields {
                headers.add(name: "\(aHeader.key)", value: "\(aHeader.value)")
            }
        }
        return (data, headers)
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

struct MultipartRequest {
    
    let boundary: String
    
    private let separator: String = "\r\n"
    private var data: Data

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
        self.data = .init()
    }
    
    private mutating func appendBoundarySeparator() {
        data.append("--\(boundary)\(separator)")
    }
    
    private mutating func appendSeparator() {
        data.append(separator)
    }

    private func disposition(_ key: String) -> String {
        "Content-Disposition: form-data; name=\"\(key)\""
    }

    mutating func add(
        key: String,
        value: String
    ) {
        appendBoundarySeparator()
        data.append(disposition(key) + separator)
        appendSeparator()
        data.append(value + separator)
    }

    mutating func add(
        key: String,
        fileName: String,
        fileMimeType: String,
        fileData: Data
    ) {
        appendBoundarySeparator()
        data.append(disposition(key) + "; filename=\"\(fileName)\"" + separator)
        data.append("Content-Type: \(fileMimeType)" + separator + separator)
        data.append(fileData)
        appendSeparator()
    }

    var httpContentTypeHeadeValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    var httpBody: Data {
        var bodyData = data
        bodyData.append("--\(boundary)--")
        return bodyData
    }
}

extension Data {

    mutating func append(
        _ string: String,
        encoding: String.Encoding = .utf8
    ) {
        guard let data = string.data(using: encoding) else {
            return
        }
        append(data)
    }
}

extension URL {
    func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        }
        else {
            return "application/octet-stream"
        }
    }
}
