//
//  Ability+Network.swift
//  
//
//  Created by 黄磊 on 2022/11/16.
//  Copyright © 2022 Miejoy. All rights reserved.
//

import Ability

extension Ability {
    /// HTTP 请求能力
    public static var network : NetworkAbility = {
        Ability.getAbility(of: networkAbilityName) as? NetworkAbility ?? DefaultHTTPDriver()
    }()
    
    /// 通用网络能力
    public static var http : HTTPAbility = {
        Ability.getAbility(with: DefaultHTTPDriver()) as! HTTPAbility
    }()
}
