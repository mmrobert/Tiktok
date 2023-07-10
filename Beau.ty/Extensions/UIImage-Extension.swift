//
//  UIImage-Extension.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-11-26.
//

import Foundation
import UIKit

extension UIImage {
    
    static let appIcon725: UIImage? = UIImage(named: "app-icon")
    static let addMedia: UIImage? = UIImage(named: "addMedia")
    
    static let flashAuto: UIImage? = UIImage(named: "flash-auto")
    static let flashLock: UIImage? = UIImage(named: "flash-lock")
    static let flashOpen: UIImage? = UIImage(named: "flash-open")
    static let cameraToggle: UIImage? = UIImage(named: "camera-toggle")
    static let gallary: UIImage? = UIImage(named: "gallary")
    static let cross: UIImage? = UIImage(named: "cross")
    
    
    // 二分法压缩，无压缩后的默认大小
    func compressImage(maxLength: Int) -> Data {
        // let tempMaxLength: Int = maxLength / 8
        let tempMaxLength: Int = maxLength
        var compression: CGFloat = 1
        guard var data = self.jpegData(compressionQuality: compression), data.count > tempMaxLength
        else { return self.jpegData(compressionQuality: compression)! }
        
        // 压缩大小
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            data = self.jpegData(compressionQuality: compression)!
            if CGFloat(data.count) < CGFloat(tempMaxLength) * 0.9 {
                min = compression
            } else if data.count > tempMaxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data)!
        if data.count < tempMaxLength { return data }
        
        // 压缩大小
        var lastDataLength: Int = 0
        while data.count > tempMaxLength && data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(tempMaxLength) / CGFloat(data.count)
            print("Ratio =", ratio)
            let size: CGSize = CGSize(width: Int(resultImage.size.width * sqrt(ratio)), height: Int(resultImage.size.height * sqrt(ratio)))
            UIGraphicsBeginImageContext(size)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            resultImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            data = resultImage.jpegData(compressionQuality: compression)!
        }
        return data
    }
    
    func compressImageTo(expectedSizeInMB: Double) -> UIImage? {
        
        let sizeInBytes = Int(expectedSizeInMB * 1024 * 1024)
        var compressingQuality: CGFloat = 1.0
        var needCompress: Bool = true
        guard var imageData = self.jpegData(compressionQuality: compressingQuality) else {
            return nil
        }
        while needCompress && compressingQuality > 0.0001 {
            if let data = self.jpegData(compressionQuality: compressingQuality) {
                imageData = data
                if data.count < sizeInBytes {
                    needCompress = false
                } else {
                    compressingQuality = compressingQuality / 3
                }
            }
        }
        return UIImage(data: imageData)
    }
}
