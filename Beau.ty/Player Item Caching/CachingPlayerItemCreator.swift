//
//  CachingPlayerItemCreator.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-07.
//

import Foundation
import AVFoundation

/// Convenient delegate methods for `PlayerItem` status updates.
public protocol CachingPlayerItemDelegate: AnyObject {
    // MARK: Downloading delegate methods
    /// Called when the media file is fully downloaded.
    func playerItem(didFinishDownloadingFileAtPath: String)
    
    /// Called every time a new portion of data is received.
    func playerItem(didDownloadBytesSoFar: Int, outOfbytesExpected: Int)
    
    /// Called on downloading error.
    func playerItem(downloadingFailedWithError: Error)
    
    // MARK: Playing delegate methods
    /// Called after initial prebuffering is finished, means we are ready to play.
    func playerItemReadyToPlay(isReady: Bool)
    
    /// Called when the player is unable to play the data/url.
    func playerItemDidFailToPlay(withError: Error?)
    
    /// Called when the data being downloaded did not arrive in time to continue playback.
    func playerItemPlaybackStalled()
}

public final class CachingPlayerItemCreator: NSObject {
    
    private let cachingPlayerItemScheme = "streaming"

    private var resourceLoaderDelegate: ResourceLoaderDelegate?
    
    private var observer: NSKeyValueObservation?
    
    public weak var delegate: CachingPlayerItemDelegate?
    
    public override init() {}
    
    /**
     Play and cache remote media.
     - parameter url: URL referencing the media file.
     - parameter saveFilePath: The desired local save location. E.g. "video.mp4". **Must** be a unique file path that doesn't already exist. If a file exists at the path than it's **required** to be empty (contain no data).
     - parameter customFileExtension: Media file extension. E.g. mp4, mp3. This is required for the player to work correctly with the intended file type.
     - parameter avUrlAssetOptions: A dictionary that contains options used to customize the initialization of the asset. For supported keys and values,
     see [Initialization Options.](https://developer.apple.com/documentation/avfoundation/avurlasset/initialization_options)
     */
    func playerItem_Caching_FromRemoteURL(url: URL, saveFilePath: String, customFileExtension: String?, avUrlAssetOptions: [String:Any]? = nil) -> AVPlayerItem {
        
        // Adding Redirect URL(customized prefix schema) to trigger AVAssetResourceLoaderDelegate
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let _ = components.scheme,
              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
            fatalError("Urls without a scheme are not supported")
        }
        
        if let ext = customFileExtension {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathExtension(ext)
        }  else {
            assert(url.pathExtension.isEmpty == false, "url pathExtension empty")
        }
        
        self.resourceLoaderDelegate = ResourceLoaderDelegate(url: url, saveFilePath: saveFilePath, owner: self)
        let asset = AVURLAsset(url: urlWithCustomScheme, options: avUrlAssetOptions)
        asset.resourceLoader.setDelegate(self.resourceLoaderDelegate, queue: DispatchQueue.main)
        
        let playItem = AVPlayerItem(asset: asset)
        self.addObserverToPlayerItem(playerItem: playItem)
        
        return playItem
    }
    
    /**
     Play from file.
     - parameter filePathURL: The local file path of a media file.
     - parameter fileExtension: Media file extension. E.g. mp4, mp3.
     - **Required**  if `filePathURL.pathExtension` is empty.
     */
    func playerItemFromLocalFile(filePathURL: URL, fileExtension: String? = nil) -> AVPlayerItem {
        var url = filePathURL
        if let fileExtension = fileExtension {
            url = filePathURL.deletingPathExtension()
            url = url.appendingPathExtension(fileExtension)
            
            // Removes old SymLinks which cause issues
            try? FileManager.default.removeItem(at: url)
            
            try? FileManager.default.createSymbolicLink(at: url, withDestinationURL: filePathURL)
        } else {
            assert(filePathURL.pathExtension.isEmpty == false, "FilePathURL pathExtension empty")
        }
        
        let asset = AVURLAsset(url: url)
        
        let playItem = AVPlayerItem(asset: asset)
        self.addObserverToPlayerItem(playerItem: playItem)
        
        return playItem
    }
    
    /**
     Play remote media **without** caching.
     - parameter nonCachingURL: URL referencing the media file.
     - parameter avUrlAssetOptions: A dictionary that contains options used to customize the initialization of the asset. For supported keys and values,
     see [Initialization Options.](https://developer.apple.com/documentation/avfoundation/avurlasset/initialization_options)
     */
    func playerItem_No_Caching_FromRemoteURL(url: URL, avUrlAssetOptions: [String:Any]? = nil) -> AVPlayerItem {
        
        let asset = AVURLAsset(url: url, options: avUrlAssetOptions)
        let playItem = AVPlayerItem(asset: asset)
        self.addObserverToPlayerItem(playerItem: playItem)
        
        return playItem
    }
    
    // MARK: Public methods
    /// Downloads the media file.
    public func download(url: URL, saveFilePath: String, customFileExtension: String?, avUrlAssetOptions: [String:Any]? = nil) {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let _ = components.scheme else {
            fatalError("Urls without a scheme are not supported")
        }
        
        var url = url
        if let ext = customFileExtension {
            url.deletePathExtension()
            url.appendPathExtension(ext)
        }  else {
            assert(url.pathExtension.isEmpty == false, "Url pathExtension empty")
        }
        
        self.resourceLoaderDelegate = ResourceLoaderDelegate(url: url, saveFilePath: saveFilePath, owner: self)
        
        self.resourceLoaderDelegate?.startDataRequest(with: url)
    }
    
    private func addObserverToPlayerItem(playerItem: AVPlayerItem) {
        
        // Register as an observer of the player item's status property
        self.observer = playerItem.observe(\.status, options: [.initial, .new], changeHandler: { [weak self] item, _ in
            let status = item.status
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                self?.delegate?.playerItemReadyToPlay(isReady: true)
            case .failed:
                // Player item failed. See error.
                print("Status: failed Error: " + item.error!.localizedDescription )
            case .unknown:
                // Player item is not yet ready.bn m
                print("Status: unknown")
            @unknown default:
                print("Status: not yet ready to present")
                break
            }
        })
    }
    
    private func removeObserver() {
        if let observer = observer {
            observer.invalidate()
        }
    }
    
    deinit {
        self.removeObserver()
        print("🍎 CachingPlayerItemCreator - deinit")
        // Otherwise the ResourceLoaderDelegate wont deallocate and will keep downloading.
        self.resourceLoaderDelegate?.invalidateAndCancelSession()
    }
}

extension CachingPlayerItemCreator: ResourceLoaderOwner {
    
    func playerItem(didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        
    }
    
    func playerItem(didFinishDownloadingFileAt filePath: String) {
        
    }
    
    func playerItem(downloadingFailedWith error: Error) {
        
    }
}
