//
//  CleanerManager.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 19.02.2021.
//

import WebKit
import SwiftKeychainWrapper
import CoreData

enum CleanerManager {
    
    static func clean(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
        do {
            let images = try context.fetch(fetchRequest)
            images.forEach {context.delete($0)}
        } catch let error {
            print(error)
        }
        do {
            try context.save()
        } catch let error {
            print(error)
        }
        WKWebView.cleanUp()
        KeychainWrapper.deleteAccessToken()
    }
}
