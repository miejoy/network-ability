//
//  Combile+Utils.swift
//  
//
//  Created by 黄磊 on 2022/11/18.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Combine

extension Publisher {
    /// 转化为 Future，暂时内部使用
    func asFuture() -> Future<Output, Failure> {
        var cancellable: AnyCancellable?
        return Future<Output, Failure> { promise in
            // cancellable is captured to assure the completion of the wrapped future
            cancellable = self.sink { completion in
                if case .failure(let error) = completion {
                    promise(.failure(error))
                }
                cancellable = nil
            } receiveValue: { value in
                promise(.success(value))
                cancellable?.cancel()
            }
        }
    }
}

extension Future {
    /// Future 添加完成回调
    public func completion(with block: @escaping (Result<Output, Error>) -> Void) {
        var cancellable: AnyCancellable?
        cancellable = self.sink { completion in
            if case .failure(let error) = completion {
                block(.failure(error))
            }
            cancellable = nil
        } receiveValue: { data in
            block(.success(data))
            cancellable?.cancel()
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
