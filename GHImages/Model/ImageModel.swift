//
//  ImageModel.swift
//  GHImages
//
//  Created by Yaroslav Hrytsun on 20.02.2021.
//

import Foundation

struct ImageModel: Codable {
    let name: String
    let downloadURL: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case downloadURL = "download_url"
    }
}
