//
//  MediaFileHandle.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-29.
//

import Foundation

/// File handle for local file operations.
final class MediaFileHandle {
    private let filePath: String
    private lazy var readHandle = FileHandle(forReadingAtPath: filePath)
    private lazy var writeHandle = FileHandle(forWritingAtPath: filePath)
    
    private let lock = NSLock()
    
    // MARK: Init
    init(filePath: String) {
        self.filePath = filePath
        
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        } else {
            print("CachingPlayerItem warning: File already exists at \(filePath).")
            print("A non empty file can cause unexpected behavior.")
        }
    }
    
    deinit {
        guard FileManager.default.fileExists(atPath: filePath) else { return }
        close()
    }
}

extension MediaFileHandle {
    
    static var diskCacheDirectoryURL: URL? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let diskDirectory = (paths.last ?? "CachesD") + "/BVideoCache"
        if !FileManager.default.fileExists(atPath: diskDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: diskDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Unable to create disk cache due to: " + error.localizedDescription)
                return nil
            }
        }
        return URL(fileURLWithPath: diskDirectory)
    }
    
    static func clearDiskCache() {
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
    }
}

// MARK: Internal methods
extension MediaFileHandle {
    var attributes: [FileAttributeKey:Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: filePath)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }
    
    var fileSize: Int {
        return attributes?[.size] as? Int ?? 0
    }
    
    func readData(withOffset offset: Int, forLength length: Int) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        readHandle?.seek(toFileOffset: UInt64(offset))
        return readHandle?.readData(ofLength: length)
    }
    
    func append(data: Data) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let writeHandle = writeHandle else { return }
        
        writeHandle.seekToEndOfFile()
        writeHandle.write(data)
    }
    
    func synchronize() {
        lock.lock()
        defer { lock.unlock() }
        
        guard let writeHandle = writeHandle else { return }
        
        writeHandle.synchronizeFile()
    }
    
    func close() {
        readHandle?.closeFile()
        writeHandle?.closeFile()
    }
    
    func deleteFile() {
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch let error {
            print("File deletion error: \(error)")
        }
    }
}
