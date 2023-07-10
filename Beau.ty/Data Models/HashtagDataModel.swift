//
//  HashtagDataModel.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-18.
//

import Foundation

struct HashtagDataModel: Codable{
    var id: String
    var name: String
    var count: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case count
    }
    
    init(id: String,
         name: String,
         count: Int) {
        self.id = id
        self.name = name
        self.count = count
    }
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        name = dictionary["name"] as? String ?? ""
        count = dictionary["count"] as? Int ?? 0
    }

    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .allowFragments]) as? [String: Any]) ?? [:]
    }
}
