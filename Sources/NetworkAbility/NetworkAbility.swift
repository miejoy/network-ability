//
//  NetworkAbility.swift
//  
//
//  Created by 黄磊 on 2022/11/14.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Ability
import Combine

/// 网络能力名称
public let networkAbilityName = AbilityName(NetworkAbility.self)

/// 网络能力
public protocol NetworkAbility: AbilityProtocol {

    /// 网络响应解码器
    var responseDecoder: NetworkResponseDecoder { get }
    
    /// 发起请求方法
    func request<E:Encodable>(
        url: URL,
        method: RequestMethod,
        body: E?,
        header: NetworkHeaders?
    ) async throws -> (data: Data, headers: NetworkHeaders)
}

extension NetworkAbility {
    public static var abilityName: AbilityName { networkAbilityName }
}

extension NetworkAbility {
    /// 发起请求方法
    func request<E:Encodable>(
        url: URL,
        method: RequestMethod,
        body: E?,
        header: NetworkHeaders?
    ) -> Future<(Data, NetworkHeaders), Error> {
        return Future<(Data, NetworkHeaders), Error>.init { promise in
            Task {
                do {
                    let response = try await self.request(url: url, method: method, body: body, header: header)
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    
    /// 发起无 body 的网络请求，获取可解码数据
    public func request<D:Decodable>(
        _ url: URL,
        _ method: RequestMethod = .get,
        header: NetworkHeaders? = nil
    ) -> Future<D, Error> {
        request(url, method, body: Optional<Data>.none, header: header)
    }
    
    /// 发起无 body 的网络请求，获取字典数据
    public func request(
        _ url: URL,
        method: RequestMethod = .get,
        header: NetworkHeaders? = nil
    ) -> Future<[String:Any], Error> {
        request(url, method: method, body: Optional<Data>.none, header: header)
    }
    
    /// 发起网络请求，获取可解码数据
    public func request<E:Encodable, D:Decodable>(
        _ url: URL,
        _ method: RequestMethod = .get,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) -> Future<D, Error> {
        request(url: url, method: method, body: body, header: header).tryMap { (responseData, responseHeaders) in
            try self.responseDecoder.decode(D.self, from: responseData, headers: responseHeaders)
        }
        .asFuture()
    }
    
    /// 发起网络请求，获取字典数据
    public func request<E:Encodable>(
        _ url: URL,
        method: RequestMethod = .get,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) -> Future<[String:Any], Error> {
        request(url: url, method: method, body: body, header: header).tryMap { (data, _) in
            if let dic = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String:Any] {
                return dic
            } else {
                throw URLError.init(.cannotDecodeRawData)
            }
        }
        .asFuture()
    }
}

/// 添加 async 扩展方法
extension NetworkAbility {
    /// 发起无 body 的网络请求，获取可解码数据
    public func request<D:Decodable>(
        _ url: URL,
        _ method: RequestMethod = .get,
        header: NetworkHeaders? = nil
    ) async throws -> D {
        try await request(url, method, body: Optional<Data>.none, header: header)
    }
    
    /// 发起无 body 的网络请求，获取字典数据
    public func request(
        _ url: URL,
        method: RequestMethod = .get,
        header: NetworkHeaders? = nil
    ) async throws -> [String:Any] {
        try await request(url, method: method, body: Optional<Data>.none, header: header)
    }
    
    /// 发起网络请求，获取可解码数据
    public func request<E:Encodable, D:Decodable>(
        _ url: URL,
        _ method: RequestMethod = .get,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) async throws -> D {
        let response = try await request(url: url, method: method, body: body, header: header)
        return try self.responseDecoder.decode(D.self, from: response.data, headers: response.headers)
    }
    
    /// 发起网络请求，获取字典数据
    public func request<E:Encodable>(
        _ url: URL,
        method: RequestMethod = .get,
        body: E? = nil,
        header: NetworkHeaders? = nil
    ) async throws -> [String:Any] {
        let response = try await request(url: url, method: method, body: body, header: header)
        guard let dic = try JSONSerialization.jsonObject(with: response.data, options: .fragmentsAllowed) as? [String:Any] else {
            throw URLError.init(.cannotDecodeRawData)
            
        }
        return dic
    }
}
