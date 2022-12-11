//
//  NetworkHeaders.swift
//  
//
//  Created by 黄磊 on 2022/11/15.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Foundation

/// 网络交互头部信息
public struct NetworkHeaders: CustomStringConvertible, ExpressibleByDictionaryLiteral {
    
    public var headers: [(String, String)]

    public var description: String {
        return self.headers.description
    }

    internal var names: [String] {
        return self.headers.map { $0.0 }
    }

    internal init(_ headers: [(String, String)] = []) {
        self.headers = headers
    }
    
    public init(dic: [String:String]) {
        self.init(dic.map { ($0.key, $0.value) })
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(elements)
    }

    public mutating func add(name: String, value: String) {
        precondition(!name.utf8.contains(where: { !$0.isASCII }), "name must be ASCII")
        self.headers.append((name, value))
    }
    
    @inlinable
    public mutating func add<S: Sequence>(contentsOf other: S) where S.Element == (String, String) {
        self.headers.reserveCapacity(self.headers.count + other.underestimatedCount)
        for (name, value) in other {
            self.add(name: name, value: value)
        }
    }
    
    public mutating func replaceOrAdd(name: String, value: String) {
        self.remove(name: name)
        self.add(name: name, value: value)
    }
    
    public mutating func remove(name nameToRemove: String) {
        self.headers.removeAll { (name, _) in
            if nameToRemove.utf8.count != name.utf8.count {
                return false
            }
            return nameToRemove.utf8.compareCaseInsensitiveASCIIBytes(to: name.utf8)
        }
    }

    public subscript(name: String) -> [String] {
        return self.headers.reduce(into: []) { target, lr in
            let (key, value) = lr
            if key.utf8.compareCaseInsensitiveASCIIBytes(to: name.utf8) {
                target.append(value)
            }
        }
    }

    public func contains(name: String) -> Bool {
        for kv in self.headers {
            if kv.0.utf8.compareCaseInsensitiveASCIIBytes(to: name.utf8) {
                return true
            }
        }
        return false
    }
}

private extension UInt8 {
    var isASCII: Bool {
        return self <= 127
    }
}

extension Sequence where Self.Element == UInt8 {
    internal func compareCaseInsensitiveASCIIBytes<T: Sequence>(to: T) -> Bool where T.Element == UInt8 {
        // fast path: we can get the underlying bytes of both
        let maybeMaybeResult = self.withContiguousStorageIfAvailable { lhsBuffer -> Bool? in
            to.withContiguousStorageIfAvailable { rhsBuffer in
                if lhsBuffer.count != rhsBuffer.count {
                    return false
                }

                for idx in 0 ..< lhsBuffer.count {
                    // let's hope this gets vectorised ;)
                    if lhsBuffer[idx] & 0xdf != rhsBuffer[idx] & 0xdf {
                        return false
                    }
                }
                return true
            }
        }

        if let maybeResult = maybeMaybeResult, let result = maybeResult {
            return result
        } else {
            return self.elementsEqual(to, by: {return ($0 & 0xdf) == ($1 & 0xdf)})
        }
    }
}
