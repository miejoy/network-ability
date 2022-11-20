//
//  NetworkContentCoder.swift
//  
//
//  Created by 黄磊 on 2022/11/16.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Combine

/// 网络请求编码器
public protocol NetworkRequestEncoder {
    func encode<E: Encodable>(_ encodable: E, headers: inout NetworkHeaders) throws -> Data
}

/// 网络响应解码器
public protocol NetworkResponseDecoder {
    func decode<D: Decodable>(_ decodable: D.Type, from data: Data, headers: NetworkHeaders) throws -> D
}

/// JSON 编码器继承网络请求编码器
extension JSONEncoder: NetworkRequestEncoder {
    public func encode<E: Encodable>(_ encodable: E, headers: inout NetworkHeaders) throws -> Data {
        if !headers.contains(name: "Content-Type") {
            headers.replaceOrAdd(name: "Content-Type", value: "application/json; charset=utf-8")
        }
        return try self.encode(encodable)
    }
}

/// JSON 解码器基础网络请求解码器
extension JSONDecoder: NetworkResponseDecoder {
    public func decode<D: Decodable>(_ decodable: D.Type, from data: Data, headers: NetworkHeaders) throws -> D {
        return try self.decode(D.self, from: data)
    }
}
