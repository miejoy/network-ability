//
//  HTTPMethod.swift
//  
//
//  Created by 黄磊 on 2022/11/15.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation

/// HTTP 请求方法
public enum HTTPMethod: CustomStringConvertible, Equatable {
    case GET
    case POST
    case custom(String)
    
    public init(with method: RequestMethod) {
        switch method {
        case .GET:
            self = .GET
        case .SET:
            self = .POST
        case .custom(let string):
            self = .custom(string)
        }
    }
    
    public var description: String {
        switch self {
        case .GET:
            return "GET"
        case .POST:
            return "POST"
        case .custom(let string):
            return string
        }
    }
}

