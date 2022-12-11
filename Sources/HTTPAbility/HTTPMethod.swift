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
    case get
    case post
    case custom(String)
    
    public init(with method: RequestMethod) {
        switch method {
        case .get:
            self = .get
        case .set:
            self = .post
        case .custom(let string):
            self = .custom(string)
        }
    }
    
    public var description: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .custom(let string):
            return string
        }
    }
}

