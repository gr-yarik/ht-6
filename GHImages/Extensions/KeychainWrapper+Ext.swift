//
//  KeychainWrapper+Ext.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 19.02.2021.
//

import SwiftKeychainWrapper

extension KeychainWrapper {
    
    private static let accessTokenKey = "accessToken"
    
    static func saveAccessTocken(accessToken: String) {
        KeychainWrapper.standard.set(accessToken, forKey: accessTokenKey)
    }
    
    
    static func getAccessToken() -> String? {
        return KeychainWrapper.standard.string(forKey: accessTokenKey)
    }
    
    
    static func deleteAccessToken() {
        KeychainWrapper.standard.remove(forKey: Key(rawValue: accessTokenKey))
    }
}
