//
//  Combile+Utils.swift
//  
//
//  Created by 黄磊 on 2022/11/18.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Combine

extension Publisher {
    /// 转化为 Future，暂时内部使用，注意：这里如果发布者没有传数据直接结束会存在泄漏
    func asFuture() -> Future<Output, Failure> {
        // 让 block 持有 cancellable
        var cancellable: AnyCancellable?
        return Future<Output, Failure> { promise in
            var didReceiveValue = false
            cancellable = self.sink { completion in
                if case .failure(let error) = completion {
                    promise(.failure(error))
                }
                cancellable = nil
            } receiveValue: { value in
                promise(.success(value))
                didReceiveValue = true
                cancellable?.cancel()
            }
            if didReceiveValue {
                // 确保同步返回的场景不会出现内存泄漏
                cancellable?.cancel()
                cancellable = nil
            }
        }
    }
}

extension Future {
    /// Future 添加完成回调，注意：这里如果发布者没有传数据直接结束会存在泄漏
    public func completion(with block: @escaping (Result<Output, Error>) -> Void) {
        var cancellable: AnyCancellable?
        var didReceiveValue = false
        cancellable = self.sink { completion in
            if case .failure(let error) = completion {
                block(.failure(error))
            }
            cancellable = nil
        } receiveValue: { data in
            block(.success(data))
            didReceiveValue = true
            cancellable?.cancel()
        }
        if didReceiveValue {
            // 确保同步返回的场景不会出现内存泄漏
            cancellable?.cancel()
            cancellable = nil
        }
    }
}

extension Result {
    /// Result 取值，可能为 nil
    public var value : Success? {
        if case let .success(data) = self {
            return data
        }
        return nil
    }
    
    /// Result 取错误，可能为 nil
    public var error : Error? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}
