//
//  URLEncodeWrapper.swift
//  
//
//  Created by 黄磊 on 2022/11/16.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation
import Ability

/// URL参数 编码 包装器
public struct URLEncodeWrapper {
    
    var run : () -> [(String, String)]
    
    public static func dic(_ dic:[String:Any]) -> Self {
        self.init { () -> [(String, String)] in
            return self.encodingUrlParams(params: dic)
        }
    }
    
    public static func model<T:Encodable>(_ model:T) -> Self {
        self.init { () -> [(String, String)] in
            var components: [(String, String)] = []
            // 使用镜像
            let mirror = Mirror(reflecting: model)
            for item in mirror.children {
                if let key = item.label {
                    if let optionValue = item.value as? AnyOptionalType {
                        if let value = optionValue.wrappedValue {
                            components += queryComponents(fromKey: key, value: value)
                        }
                    } else {
                        components += queryComponents(fromKey: key, value: item.value)
                    }
                }
            }
            return components
        }
    }
    
    public func encode(into url: inout URL) {
        let components = self.run()
        if !components.isEmpty {
            let params = components.map { "\($0)=\($1)" }.joined(separator: "&")
            var urlStr = url.absoluteString
            if urlStr.contains("?") {
                urlStr += ("&" + params)
            } else {
                urlStr += ("?" + params)
            }
            if let newUrl = URL(string: urlStr) {
                url = newUrl
            }
        }
    }
    
    public func encode(into request: inout URLRequest) {
        let components = self.run()
        if !components.isEmpty {
            let params = components.map { "\($0)=\($1)" }.joined(separator: "&")
            request.allHTTPHeaderFields?["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"
            request.httpBody = params.data(using: .utf8)
        }
    }
    
    public func getParams() -> String? {
        let components = self.run()
        if !components.isEmpty {
            return components.map { "\($0)=\($1)" }.joined(separator: "&")
        }
        return nil
    }
    
    func encode(into request: inout MultipartRequest) {
        let components = self.run()
        if !components.isEmpty {
            components.forEach { item in
                request.add(key: item.0, value: item.1)
            }
        }
    }
    
    /// URL 编码数据
    static func encodingUrlParams(params: [String:Any]) -> [(String, String)] {
        var components: [(String, String)] = []
        
        for key in params.keys.sorted(by: <) {
            let value = params[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components
    }
    
    static func queryComponents(fromKey key: String, value: Any?) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any?] {
            if key.count == 0 {
                for (nestedKey, value) in dictionary {
                    components += queryComponents(fromKey: "\(nestedKey)", value: value)
                }
            } else {
                for (nestedKey, value) in dictionary {
                    components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
                }
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let value = value {
            // 尝试镜像
            let mirror = Mirror(reflecting: value)
            if mirror.children.isEmpty {
                components.append((escape(key), escape("\(value)")))
            } else {
                for item in mirror.children {
                    if let key = item.label {
                        components += queryComponents(fromKey: key, value: item.value)
                    }
                }
            }
        } else {
            components.append((escape(key), "NULL"))
        }

        return components
    }
    
    /// 字符串转译
    static func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        var escaped = ""

        escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string

        return escaped
    }
}
