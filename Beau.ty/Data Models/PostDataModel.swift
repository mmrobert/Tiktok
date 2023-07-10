//
//  VideoDataModel.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-15.
//

import Foundation

struct PostDataModel: Codable{
    var id: String
    var videoName: String?
    var videoURL: URL?
    var videoFileExtension: String?
    var videoHeight: Int?
    var videoWidth: Int?
    var autherID: String?
    var autherName: String
    var caption: String?
    var music: String?
    var hashtags: [String] = []
    var broadcastLink: String?
    var likeCount: Int = 0
    var shareCount: Int = 0
    var commentID: String?
    var timeCreated: String?
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case videoName
        case videoURL
        case videoFileExtension
        case videoHeight
        case videoWidth
        case autherID
        case autherName
        case caption
        case music
        case hashtags
        case broadcastLink
        case likeCount
        case shareCount
        case commentID
        case timeCreated
    }
    
    init(id: String,
         videoName: String?,
         videoURL: URL?,
         videoFileExtension: String?,
         videoHeight: Int?,
         videoWidth: Int?,
         autherID: String?,
         autherName: String,
         caption: String?,
         music: String?,
         hashtags: [String] = [],
         broadcastLink: String?,
         likeCount: Int = 0,
         shareCount: Int = 0,
         commentID: String?,
         timeCreated: String?) {
        self.id = id
        self.videoName = videoName
        self.videoURL = videoURL
        self.videoFileExtension = videoFileExtension
        self.videoHeight = videoHeight
        self.videoWidth = videoWidth
        self.autherID = autherID
        self.autherName = autherName
        self.caption = caption
        self.music = music
        self.hashtags = hashtags
        self.broadcastLink = broadcastLink
        self.likeCount = likeCount
        self.shareCount = shareCount
        self.commentID = commentID
        self.timeCreated = timeCreated
    }
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        videoName = dictionary["videoName"] as? String
        let urlString = dictionary["videoURL"] as? String ?? ""
        videoURL = URL(string: urlString)
        videoFileExtension = dictionary["videoFileExtension"] as? String
        videoHeight = dictionary["videoHeight"] as? Int
        videoWidth = dictionary["videoWidth"] as? Int
        autherID = dictionary["authorID"] as? String
        autherName = dictionary["autherName"] as? String ?? ""
        caption = dictionary["caption"] as? String
        music = dictionary["music"] as? String
        hashtags = dictionary["hashtags"] as? [String] ?? []
        broadcastLink = dictionary["broadcastLink"] as? String
        likeCount = dictionary["likeCount"] as? Int ?? 0
        shareCount = dictionary["shareCount"] as? Int ?? 0
        commentID = dictionary["commentID"] as? String
        timeCreated = dictionary["timeCreated"] as? String
    }

    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .allowFragments]) as? [String: Any]) ?? [:]
    }
}
