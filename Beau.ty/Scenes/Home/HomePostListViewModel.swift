//
//  HomePostListViewModel.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-22.
//

import Foundation
import Combine

class HomePostListViewModel: ObservableObject {
    
    var postsList: [HomePostItemViewModel] = []
    
    private var disposables = Set<AnyCancellable>()
    
    @Published var postsAdded: [HomePostItemViewModel] = []
    @Published var postsModified: [HomePostItemViewModel] = []
    @Published var postsRemoved: [HomePostItemViewModel] = []
    
    init() {
        
    }
    
    func fetchPosts(completion: @escaping (Result<[HomePostItemViewModel], Error>) -> Void) {
        FirebaseNetworkService.shared.fetchPosts() { [weak self] result in
            switch result {
            case .success(let posts):
                let postVM = posts.map {
                    HomePostItemViewModel(
                        id: $0.id,
                        videoURL: $0.videoURL,
                        videoFileExtension: $0.videoFileExtension,
                        videoWidth: $0.videoWidth ?? 9,
                        videoHeight: $0.videoHeight ?? 16,
                        autherName: $0.autherName
                    )
                }
                self?.postsList = postVM
                completion(.success(postVM))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func observeDBChange() {
        FirebaseNetworkService.shared.$postsAdded
            .sink(receiveValue: { [weak self] addedList in
                guard let strongSelf = self else { return }
                let addedVM = addedList.map {
                    HomePostItemViewModel(
                        id: $0.id,
                        videoURL: $0.videoURL,
                        videoFileExtension: $0.videoFileExtension,
                        videoWidth: $0.videoWidth ?? 9,
                        videoHeight: $0.videoHeight ?? 16,
                        autherName: $0.autherName
                    )
                }
                strongSelf.postsAdded = addedVM
            })
            .store(in: &disposables)
        FirebaseNetworkService.shared.$postsModified
            .sink(receiveValue: { [weak self] modifiedList in
                guard let strongSelf = self else { return }
                let modifiedVM = modifiedList.map {
                    HomePostItemViewModel(
                        id: $0.id,
                        videoURL: $0.videoURL,
                        videoFileExtension: $0.videoFileExtension,
                        videoWidth: $0.videoWidth ?? 9,
                        videoHeight: $0.videoHeight ?? 16,
                        autherName: $0.autherName
                    )
                }
                strongSelf.postsModified = modifiedVM
            })
            .store(in: &disposables)
        FirebaseNetworkService.shared.$postsRemoved
            .sink(receiveValue: { [weak self] removedList in
                guard let strongSelf = self else { return }
                let removedVM = removedList.map {
                    HomePostItemViewModel(
                        id: $0.id,
                        videoURL: $0.videoURL,
                        videoFileExtension: $0.videoFileExtension,
                        videoWidth: $0.videoWidth ?? 9,
                        videoHeight: $0.videoHeight ?? 16,
                        autherName: $0.autherName
                    )
                }
                strongSelf.postsRemoved = removedVM
            })
            .store(in: &disposables)
        
        FirebaseNetworkService.shared.observeDBChange()
    }
    
    func deleteVideoCache(ids: [String]) {
        /*
        let dispatchQueue = DispatchQueue(label: "com.VideoCache")
        dispatchQueue.async {
            do {
                let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
                let diskDirectory = (paths.last ?? "CachesD") + "/BVideoCache"
                let contents = try FileManager.default.contentsOfDirectory(atPath: diskDirectory)
                var folderSize: Float = 0
                for name in contents {
                    let path = diskDirectory + "/" + name
                    let fileDict = try FileManager.default.attributesOfItem(atPath: path)
                    folderSize += fileDict[FileAttributeKey.size] as! Float
                    try FileManager.default.removeItem(atPath: path)
                }
                // Unit: MB
                let clearSize = (folderSize/1024.0/1024.0).format() ?? ""
                print("Clear size: \(clearSize)")
            } catch {
                print("clearDiskCache error:" + error.localizedDescription)
            }
        }
         */
    }
    
    
    
    
    static func sampleVideos() -> [URL] {
        var res: [URL] = []
        let names = ["waterFall", "HowDoes", "RiceKrispies", "Gorilla2018"]
        
        for name in names {
            if let contentURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
                res.append(contentURL)
            }
        }
        return res
    }
}
