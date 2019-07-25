//
//  SessionStore.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/5/5.
//

import Foundation

public protocol UserSessionStore {
    func saveInfo(_ info: [String: String])
    func getInfo(key: String) -> String?
    func deleteInfo(key: String)
}

/// 管理用户登录信息
class CloudUserSessionStore: UserSessionStore {
    
    private var key: String?
    
    func deleteInfo(key: String) {
        UserDefaults.standard.set(nil, forKey: "imKey" + key)
    }
    
    func getInfo(key: String) -> String? {
        if let value = UserDefaults.standard.value(forKey:key) as? String {
            return value
        } else {
            return nil
        }
    }
    
    func saveInfo(_ info: [String : String]) {
        guard let key = info.keys.first else { return }
        guard let value = info.values.first else { return }
        self.key = key
        UserDefaults.standard.set(value, forKey: "imKey" + key)
    }
    
}

