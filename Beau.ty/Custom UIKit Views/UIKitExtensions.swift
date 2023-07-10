//
//  UIKitExtensions.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-10.
//

import Foundation
import UIKit

extension CABasicAnimation {
    /// Creates an animation that pulses once.
    ///
    /// - Parameters:
    ///   - beginOpacity: start opacity
    ///   - endOpacity: end opacity
    ///   - duration: duration
    /// - Returns: animation
    static func fade(beginOpacity: CGFloat, endOpacity: CGFloat, duration: CFTimeInterval) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = beginOpacity
        animation.toValue = endOpacity
        animation.autoreverses = true
        animation.duration = duration
        animation.repeatCount = 0
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.isRemovedOnCompletion = true
        return animation
    }
}
