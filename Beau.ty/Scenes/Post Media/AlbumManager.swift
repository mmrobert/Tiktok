//
//  AlbumManager.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-12-30.
//

import Foundation
import UIKit
import PhotosUI

protocol AlbumManagerDelegate: AnyObject {
    func didFinishPicking(videoURL: URL)
}

class AlbumManager: NSObject {
    
    weak var delegate: AlbumManagerDelegate?
    
    weak private var presenter: UIViewController?
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func presentVideoPickerViewController() {
        
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        // Set the mode to avoid transcoding, if possible,
        // if your app supports arbitrary image/video encodings.
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        //picker.modalPresentationStyle = .fullScreen
        //picker.modalTransitionStyle = .crossDissolve
        picker.hidesBottomBarWhenPushed = true
        self.presenter?.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.presenter?.navigationController?.pushViewController(picker, animated: true)
    }
    
    private func saveToAlbum(fileURL: URL, onQueue: DispatchQueue) {
        onQueue.async {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Save the movie file to the photo library
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: fileURL, options: options)
                    }, completionHandler: { success, error in
                        if !success {
                            print("couldn't save to your photo library: \(String(describing: error))")
                        }
                    })
                }
            }
        }
    }
}

extension AlbumManager: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        if results.isEmpty {
            picker.navigationController?.popToRootViewController(animated: true)
        }
        
        guard let itemProvider = results.first?.itemProvider else {
            return
        }
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            let progress: Progress = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                guard let sSelf = self else { return }
                do {
                    guard let url = url, error == nil else {
                        throw error ?? NSError(domain: NSFileProviderErrorDomain, code: -1, userInfo: nil)
                    }
                    let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.removeItem(at: localURL)
                    try FileManager.default.copyItem(at: url, to: localURL)
                    DispatchQueue.main.async {
                        sSelf.delegate?.didFinishPicking(videoURL: localURL)
                    }
                } catch let catchedError {
                    DispatchQueue.main.async {
                        print("Couldn't play video with error: \(catchedError)")
                    }
                }
            }
        }
    }
}
