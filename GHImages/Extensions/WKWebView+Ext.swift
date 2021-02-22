//
//  WKWebView+Ext.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 19.02.2021.
//

import WebKit

extension WKWebView {
    static func cleanUp() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records.filter { $0.displayName.contains("github")}, completionHandler: {})
        }
    }
}
