# NetworkAbility

NetworkAbility 提供从网络获取资源能力。

[![Swift](https://github.com/miejoy/network-ability/actions/workflows/test.yml/badge.svg)](https://github.com/miejoy/network-ability/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/miejoy/network-ability/branch/main/graph/badge.svg)](https://codecov.io/gh/miejoy/network-ability)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-5.7-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 13.0+ / macOS 10.15+
- Xcode 14.0+
- Swift 5.7+

## 简介

该模块提供如下通用网络能力：
- NetworkAbility : 通用网络能力，继承该协议，需要实现对应请求网络资源方法
- Ability.network : 读取当前网络能力，默认使用 DefaultHTTPDriver
- RequestMethod : 请求方法，目前提供 get 和 set，对应 HTTP 的 get 和 post
- NetworkHeaders : 网络请求或响应头部信息

以及 HTTP 请求能力：
- HTTPAbility : 最新资源能力协议，继承该协议，需要实现对应 HTTP 请求方法
- Ability.http : 读取当前 HTTP 能力，默认使用 DefaultHTTPDriver
- RequestMethod : HTTP 请求方法，目前提供 get 和 post，可通过 RequestMethod 转化过来
- DefaultHTTPDriver : 默认 HTTP 请求驱动，继承 HTTPAbility
- URLEncodeWrapper : URL 参数编码包装器，可以包装 Encodable 数据 或者 字典

## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖:

```swift
dependencies: [
    .package(url: "https://github.com/miejoy/network-ability.git", from: "0.1.0"),
]
```

## 使用

### 使用通用网络能力

```swift
import NetworkAbility

let url = URL(string: "")!
let response = try await Ability.network.request(url)
print(response)

```

### 使用 HTTP 请求能力

```swift
import NetworkAbility

let url = URL(string: "")!
let response = try await Ability.http.httpRequest(url)
print(response)
```

### 能力注册

注册方式统一使用 AutoConfig 提供的自动注册，详见: https://github.com/miejoy/auto-config


## 作者

Raymond.huang: raymond0huang@gmail.com

## License

NetworkAbility is available under the MIT license. See the LICENSE file for more info.
