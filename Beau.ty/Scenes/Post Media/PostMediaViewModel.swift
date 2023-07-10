//
//  PostMediaViewModel.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-04.
//

import Foundation
import Combine
import FirebaseStorage
import FirebaseFirestore

class PostMediaViewModel: ObservableObject {
    
    let HashtagCollectionName = "Hashtags"  // for firebase
    
    var videoURL: URL?
    var caption: String?
    @Published var hashtags: [String] = []
    var broadcastLink: String?
    var videoWidth: Int = 9
    var videoHeight: Int = 16
    var timeCreated: String?
    
    func publishVideoToStorage(progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard let url = videoURL else { return }
        FirebaseNetworkService.shared.publishVideoToStorage(
            videoURL: url,
            progress: { fraction in
                progress(fraction)
        },
            completion: { [weak self] result in
                switch result {
                case .success(let savedURL):
                    self?.videoURL = savedURL
                    self?.timeCreated = self?.nowString()
                    self?.publishPostToDB() { error in
                        if let err = error {
                            completion(.failure(err))
                        } else {
                            completion(.success(savedURL))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
        })
    }
    
    private func publishPostToDB(completion: @escaping (Error?) -> Void) {
        
        let post = PostDataModel(
            id: "",
            videoName: nil,
            videoURL: self.videoURL,
            videoFileExtension: "mp4",
            videoHeight: self.videoHeight,
            videoWidth: self.videoWidth,
            autherID: nil,
            autherName: "Cheng",
            caption: self.caption,
            music: nil,
            hashtags: self.hashtags,
            broadcastLink: self.broadcastLink,
            commentID: nil,
            timeCreated: self.timeCreated
        )
        FirebaseNetworkService.shared.publishPostToDB(data: post, completion: completion)
    }
    
    func fetchHashtags(completion: @escaping (Result<[HashtagDataModel], Error>) -> Void) {
        
        FirebaseNetworkService.shared.fetchHashtags(completion: completion)
    }
    
    func resetViewModel() {
        self.videoURL = nil
        self.caption = nil
        self.hashtags = []
        self.broadcastLink = nil
        self.videoWidth = 9
        self.videoHeight = 16
        self.timeCreated = nil
    }
    
    private func nowString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        let timeStr = formatter.string(from: Date())
        return timeStr
    }
}
