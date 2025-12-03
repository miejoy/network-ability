//
//  HTTPDriver.swift
//  
//
//  Created by 黄磊 on 2022/11/14.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Ability
import Foundation
import Combine

/// HTTP 能力名称
public let httpAbilityName = AbilityName(HTTPAbility.self)

/// HTTP 能力
public protocol HTTPAbility: NetworkAbility {
    func httpRequest<E:Encodable>(
        url: URL,
        method: HTTPMethod,
        formData: URLEncodeWrapper?,
        body: E?,
        header: NetworkHeaders?
    ) async throws -> (data: Data, headers: NetworkHeaders)
    
    func httpUpload(
        url: URL,
        files: [URL],
        filesKey: String,
        method: HTTPMethod,
        formData: URLEncodeWrapper?,
        header: NetworkHeaders?
    ) async throws -> (data: Data, header: NetworkHeaders)
}

extension HTTPAbility {
    public static var abilityName: AbilityName { httpAbilityName }
}

extension HTTPAbility {
    func httpRequest<E:Encodable>(
        url: URL,
        method: HTTPMethod,
        formData: URLEncodeWrapper?,
        body: E?,
        header: NetworkHeaders?
    ) -> Future<(Data, NetworkHeaders), Error> {
        return Future<(Data, NetworkHeaders), Error>.init { promise in
            Task {
                do {
                    let response = try await self.httpRequest(url: url, method: method, formData: formData, body: body, header: header)
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    public func request<E:Encodable>(
        url: URL,
        method: RequestMethod,
        body: E?,
        header: NetworkHeaders?
    ) async throws -> (data: Data, headers: NetworkHeaders) {
        try await httpRequest(url: url, method: .init(with: method), formData: nil, body: body, header: header)
    }
}

extension HTTPAbility {
    /// 发起无 body 的网络请求，获取可解码数据
    public func httpRequest<D:Decodable>(
        _ url: URL,
        _ method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        header: NetworkHeaders? = nil
    ) -> Future<D, Error> {
        httpRequest(url, method, formData: formData, body: Optional<Data>.none, header: header)
    }
    
    /// 发起无 body 的网络请求，获取字典数据
    public func httpRequest(
        _ url: URL,
        method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        header: NetworkHeaders? = nil
    ) -> Future<[String:Any], Error> {
        httpRequest(url, method: method, formData: formData, body: Optional<Data>.none, header: header)
    }
    
    /// 发起网络请求，获取可解码数据
    public func httpRequest<E:Encodable, D:Decodable>(
        _ url: URL,
        _ method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) -> Future<D, Error> {
        httpRequest(url: url, method: method, formData: formData, body: body, header: header).tryMap { (responseData, responseHeaders) in
            try self.responseDecoder.decode(D.self, from: responseData, headers: responseHeaders)
        }
        .asFuture()
    }
    
    /// 发起网络请求，获取字典数据
    public func httpRequest<E:Encodable>(
        _ url: URL,
        method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) -> Future<[String:Any], Error> {
        httpRequest(url: url, method: method, formData: formData, body: body, header: header).tryMap { (data, _) in
            if let dic = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String:Any] {
                return dic
            } else {
                throw URLError.init(.cannotDecodeRawData)
            }
        }
        .asFuture()
    }
    
    /// 发起文件上传
    public func httpUpload<D:Decodable>(
        _ url: URL,
        files: [URL],
        filesKey: String = "files",
        method: HTTPMethod = .post,
        formData: URLEncodeWrapper? = nil,
        header: NetworkHeaders? =  nil
    ) async throws -> (data: D, header: NetworkHeaders) {
        let response = try await httpUpload(url: url, files: files, filesKey: filesKey, method: method, formData: formData, header: header)
        return (try self.responseDecoder.decode(D.self, from: response.data, headers: response.header), response.header)
    }
    
    /// 发起多文件上传
    public func httpUpload(
        _ url: URL,
        file: URL,
        fileKey: String = "file",
        method: HTTPMethod = .post,
        formData: URLEncodeWrapper? = nil,
        header: NetworkHeaders? =  nil
    ) async throws -> (data: [String:Any], header: NetworkHeaders) {
        let response = try await httpUpload(url: url, files: [file], filesKey: fileKey, method: method, formData: formData, header: header)
        if let dic = try JSONSerialization.jsonObject(with: response.0, options: .fragmentsAllowed) as? [String:Any] {
            return (dic, response.1)
        } else {
            throw URLError.init(.cannotDecodeRawData)
        }
    }
    
    /// 发起多文件上传
    public func httpUpload(
        _ url: URL,
        files: [URL],
        filesKey: String = "files",
        method: HTTPMethod = .post,
        formData: URLEncodeWrapper? = nil,
        header: NetworkHeaders? =  nil
    ) async throws -> (data: [String:Any], header: NetworkHeaders) {
        let response = try await httpUpload(url: url, files: files, filesKey: filesKey, method: method, formData: formData, header: header)
        if let dic = try JSONSerialization.jsonObject(with: response.0, options: .fragmentsAllowed) as? [String:Any] {
            return (dic, response.1)
        } else {
            throw URLError.init(.cannotDecodeRawData)
        }
    }
}

/// 添加 async 扩展方法
extension HTTPAbility {
    /// 发起无 body 的网络请求，获取可解码数据
    public func httpRequest<D:Decodable>(
        _ url: URL,
        _ method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        header: NetworkHeaders? = nil
    ) async throws -> D {
        try await httpRequest(url, method, formData: formData, body: Optional<Data>.none, header: header)
    }
    
    /// 发起无 body 的网络请求，获取字典数据
    public func httpRequest(
        _ url: URL,
        method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        header: NetworkHeaders? = nil
    ) async throws -> [String:Any] {
        try await httpRequest(url, method: method, formData: formData, body: Optional<Data>.none, header: header)
    }
    
    /// 发起网络请求，获取可解码数据
    public func httpRequest<E:Encodable, D:Decodable>(
        _ url: URL,
        _ method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) async throws -> D {
        let response = try await httpRequest(url: url, method: method, formData: formData, body: body, header: header)
        return try self.responseDecoder.decode(D.self, from: response.data, headers: response.headers)
    }
    
    /// 发起网络请求，获取字典数据
    public func httpRequest<E:Encodable>(
        _ url: URL,
        method: HTTPMethod = .get,
        formData: URLEncodeWrapper? = nil,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) async throws -> [String:Any] {
        let response = try await httpRequest(url: url, method: method, formData: formData, body: body, header: header)
        guard let dic = try JSONSerialization.jsonObject(with: response.data, options: .fragmentsAllowed) as? [String:Any] else {
            throw URLError.init(.cannotDecodeRawData)
        }
        return dic
    }
}
