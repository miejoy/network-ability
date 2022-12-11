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
    ) -> Future<(Data, NetworkHeaders), Error>
}

extension HTTPAbility {
    public static var abilityName: AbilityName { httpAbilityName }
}

extension HTTPAbility {
    public func request<E:Encodable>(
        url: URL,
        method: RequestMethod,
        body: E?,
        header: NetworkHeaders?
    ) -> Future<(Data, NetworkHeaders), Error> {
        httpRequest(url: url, method: .init(with: method), formData: nil, body: body, header: header)
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
}


