//
//  HomePostItemViewModel.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-22.
//

import Foundation
import Combine

class HomePostItemViewModel: ObservableObject {
    
    var id: String?
    var videoURL: URL?
    var videoFileExtension: String?
    var videoWidth: Int = 9
    var videoHeight: Int = 16
    var autherName: String?
    
    init(id: String?,
         videoURL: URL?,
         videoFileExtension: String?,
         videoWidth: Int,
         videoHeight: Int,
         autherName: String?) {
        self.id = id
        self.videoURL = videoURL
        self.videoFileExtension = videoFileExtension
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
        self.autherName = autherName
    }
}
