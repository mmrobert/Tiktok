//
//  HighlightView.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-09.
//

import Foundation
import UIKit

class HighlightView: UIView {
    
    public let kHighlightAnimationKey = "Highlight"
    
    var isAnimating: Bool {
        return self.layer.animation(forKey: kHighlightAnimationKey) != nil
    }
    
    /// stops / resets the animation state
    func stopAnimation() {
        // remove the animation before we start a new one
        if let _ = self.layer.animation(forKey: kHighlightAnimationKey) {
            self.layer.removeAllAnimations()
            self.isHidden = true
        }
    }
    
    /// Plays the animation indefinitely
    ///
    /// - Parameters:
    ///   - color: background color
    ///   - beginOpacity: beginning opacity
    ///   - endOpacity: end opacity
    ///   - duration: duration to achieve the end opacity, it'll also take that duration to animate back to the
    ///     begin opacity. So the duration of the full animation is actually 2 times the duration
    ///
    func startAnimation(color: UIColor?, beginOpacity: CGFloat, endOpacity: CGFloat, duration: CFTimeInterval) {
        guard isAnimating == false else { return }
        
        if let c = color {
            // For the time being, I'm just going to apply an alpha'd out view.
            // If we wanted to do what was done in the mock out, I would have to set
            // a gradient as the mask and then fill the area with the color... I think
            
            self.isHidden = false
            
            // set it's color
            self.backgroundColor = c
            
            // and animate
            let animation = CABasicAnimation.fade(beginOpacity: beginOpacity, endOpacity: endOpacity, duration: duration)
            
            animation.repeatCount = .infinity
            animation.delegate = self
            self.layer.add(animation, forKey: kHighlightAnimationKey)
        } else {
            self.isHidden = true
        }
    }
}

extension HighlightView: CAAnimationDelegate {
    // MARK: - CAAnimationDelegate
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.isHidden = true
    }
}
