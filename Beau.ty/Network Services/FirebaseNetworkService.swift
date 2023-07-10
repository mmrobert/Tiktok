//
//  FirebaseNetworkService.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-04.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore

class FirebaseNetworkService: ObservableObject {
    
    let HashtagCollectionName = "Hashtags"  // for firebase
    let PostsCollectionName = "posts"  // for firebase
    let VideoFileExtension = "mp4"  // for firebase
    
    static let shared = FirebaseNetworkService()
    
    private let fbStorage = Storage.storage()
    private let fbDatabase = Firestore.firestore()
    
    @Published var postsAdded: [PostDataModel] = []
    @Published var postsModified: [PostDataModel] = []
    @Published var postsRemoved: [PostDataModel] = []
    
    private init() {}
    
    func fetchPosts(completion: @escaping (Result<[PostDataModel], Error>) -> Void) {
        let dbRef = fbDatabase.collection(PostsCollectionName)
        dbRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                var allPosts: [PostDataModel] = []
                for post in snapshot.documents {
                    var postDataModel = PostDataModel(dictionary: post.data())
                    postDataModel.id = post.documentID
                    allPosts.append(postDataModel)
                }
                completion(.success(allPosts))
            }
        }
    }
    
    func observeDBChange() {
        let dbRef = fbDatabase.collection(PostsCollectionName)
        dbRef.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(String(describing: error))")
                return
            }
            var added: [PostDataModel] = []
            var modified: [PostDataModel] = []
            var removed: [PostDataModel] = []
            snapshot.documentChanges.forEach { diff in
                var postDataModel = PostDataModel(dictionary: diff.document.data())
                postDataModel.id = diff.document.documentID
                if (diff.type == .added) {
                    added.append(postDataModel)
                }
                if (diff.type == .modified) {
                    modified.append(postDataModel)
                }
                if (diff.type == .removed) {
                    removed.append(postDataModel)
                }
            }
            if added.count > 0 {
                self.postsAdded = added
            }
            if modified.count > 0 {
                self.postsModified = modified
            }
            if removed.count > 0 {
                self.postsRemoved = removed
            }
        }
    }
    
    func publishVideoToStorage(videoURL: URL, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        let nowTime = self.nowString()
        let videoName = UUID().uuidString + "-" + nowTime
        let dateStr = "D" + self.dateString()
        let path = "\(dateStr)/\(videoName).\(VideoFileExtension)"
        let videoRef = fbStorage.reference(withPath: path)
        
        let uploadTask = videoRef.putFile(from: videoURL, metadata: nil) { result in
            switch result {
            case .success(_):
                videoRef.downloadURL { (savedURL, err) in
                    if let savedURL = savedURL {
                        completion(.success(savedURL))
                    } else if let err = err {
                        completion(.failure(err))
                    } else {
                        return
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        uploadTask.observe(.progress) { snapshot in
            guard let fraction = snapshot.progress?.fractionCompleted else {
                return
            }
            progress(fraction)
        }
    }
    
    func publishPostToDB(data: PostDataModel, completion: @escaping (Error?) -> Void) {
        
        let dbRef = fbDatabase.collection(PostsCollectionName)
        var dictionaryData = data.dictionary
        dictionaryData.removeValue(forKey: "id")
        dbRef.document().setData(dictionaryData) { error in
            completion(error)
        }
    }
    
    func fetchHashtags(completion: @escaping (Result<[HashtagDataModel], Error>) -> Void) {
        let dbRef = fbDatabase.collection(HashtagCollectionName)
        dbRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot {
                var allHashtags: [HashtagDataModel] = []
                for tag in snapshot.documents {
                    var hashtagDataModel = HashtagDataModel(dictionary: tag.data())
                    hashtagDataModel.id = tag.documentID
                    allHashtags.append(hashtagDataModel)
                }
                completion(.success(allHashtags))
            }
        }
    }
    
    
    
    
    private func nowString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        let timeStr = formatter.string(from: Date())
        return timeStr
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let timeStr = formatter.string(from: Date())
        return timeStr
    }
}
