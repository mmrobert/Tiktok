//
//  VideoPrefetchToLocalFile.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-22.
//

import Foundation
import AVFoundation

public protocol VideoPrefetchToLocalFileDelegate: AnyObject {
    // MARK: Downloading delegate methods
    /// Called when the media file is fully downloaded.
    func playerItem(didFinishDownloadingFileAtPath: String)
    
    /// Called every time a new portion of data is received.
    func playerItem(didDownloadBytesSoFar: Int, outOfbytesExpected: Int)
    
    /// Called on downloading error.
    func playerItem(downloadingFailedWithError: Error)
}

public final class VideoPrefetchToLocalFile: NSObject {
    
    private var resourceLoaderDelegate: ResourceLoaderDelegate?
    
    public weak var delegate: VideoPrefetchToLocalFileDelegate?
    
    public override init() {}
    
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
    
    func cancelDownloading() {
        self.resourceLoaderDelegate?.invalidateAndCancelSession()
    }
    
    deinit {
        print("🍎 VideoPrefetchToLocalFile - deinit")
        // Otherwise the ResourceLoaderDelegate wont deallocate and will keep downloading.
        self.resourceLoaderDelegate?.invalidateAndCancelSession()
    }
}

extension VideoPrefetchToLocalFile: ResourceLoaderOwner {
    
    func playerItem(didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        
    }
    
    func playerItem(didFinishDownloadingFileAt filePath: String) {
        
    }
    
    func playerItem(downloadingFailedWith error: Error) {
        
    }
}
