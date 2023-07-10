//
//  RadialGradientView.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-10.
//

import Foundation
import UIKit

class RadialGradientView: UIView {
    
    let kAnimationKey = "Pulse"
    
    var isAnimating: Bool {
        return self.layer.animation(forKey: kAnimationKey) != nil
    }
    
    var color: UIColor = .clear {
        willSet {
            let colorChange = newValue.isEqual(self.color) == false
            if colorChange {
                self.setNeedsDisplay()
            }
        }
    }
    
    var startingAlpha: CGFloat = 0.5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false
    }
    
    override func draw(_ rect: CGRect) {
        // An optimization can be done where the gradient is drawn into an image,
        // that way setNeedsDisplay won't have to be called when it starts animating.
        // This option should be chosen if it causes off screen rendering.
        
        let colors = [
            self.color.withAlphaComponent(startingAlpha).cgColor,
            self.color.withAlphaComponent(0.0).cgColor
        ] as CFArray
 
        guard let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil) else {
            return
        }
 
        let divisor: CGFloat = 3
        let endRadius = sqrt(pow(frame.width/divisor, 2) + pow(frame.height/divisor, 2))
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
 
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.drawRadialGradient(gradient,
                                    startCenter: center,
                                    startRadius: 0.0,
                                    endCenter: center,
                                    endRadius: endRadius,
                                    options: .drawsBeforeStartLocation)
        context?.restoreGState()
    }
    
    /// Pulses until stopAnimation is called
    func startAnimation() {
        guard self.isAnimating == false else {
            return
        }
        
        // clear out old animations
        self.layer.removeAllAnimations()
        
        let animation = CABasicAnimation.fade(beginOpacity: 1.0, endOpacity: 0.5, duration: 0.5)
        animation.repeatCount = .infinity
        self.layer.add(animation, forKey: kAnimationKey)
        self.isHidden = false
    }
    
    func stopAnimation() {
        self.layer.removeAllAnimations()
        self.isHidden = true
    }
}
