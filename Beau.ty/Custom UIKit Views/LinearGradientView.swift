//
//  LinearGradientView.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-09.
//

import Foundation
import UIKit

public class LinearGradientView: UIView {
    
    private struct Constants {
        static let stopLocations: [CGFloat] = [0.0, 0.05, 0.25, 0.45, 0.65, 1.0]
        static let stopColors: [UIColor] = [
            UIColor(red: 178.0/255.0, green: 0.0, blue: 0.0, alpha: 1.0),
            UIColor(red: 178.0/255.0, green: 0.0, blue: 0.0, alpha: 1.0),
            UIColor(red: 1.0, green: 213.0/255.0, blue: 46.0/255.0, alpha: 1.0),
            UIColor(red: 1.0, green: 213.0/255.0, blue: 46.0/255.0, alpha: 1.0),
            UIColor(red: 117.0/255.0, green: 206.0/255.0, blue: 36.0/255.0, alpha: 1.0),
            UIColor(red: 117.0/255.0, green: 206.0/255.0, blue: 36.0/255.0, alpha: 1.0)]
    }
    
    public enum GradientDirection {
        case vertical
        case horizontal
    }
    
    private var colors: [UIColor] = Constants.stopColors
    private var colorLocations: [CGFloat] = Constants.stopLocations
    private var direction: LinearGradientView.GradientDirection = .vertical
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(frame: CGRect, colors: [UIColor], colorLocations: [CGFloat], direction: LinearGradientView.GradientDirection = .vertical) {
        self.init(frame: frame)
        self.colors = colors
        self.colorLocations = colorLocations
        self.direction = direction
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let colors = self.colors.map { $0.cgColor }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: self.colorLocations
        ) else {
            return
        }
        
        let startPoint = CGPoint.zero
        var endPoint = CGPoint(x: 0, y: bounds.height)
        if self.direction == .horizontal {
            endPoint = CGPoint(x: bounds.width, y: 0)
        }
        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: []
        )
    }
    
    public func setColorsAndLocations(colors: [UIColor], colorLocations: [CGFloat]) {
        self.colors = colors
        self.colorLocations = colorLocations
        setNeedsDisplay()
    }
    
    public func setDirection(direction: LinearGradientView.GradientDirection) {
        self.direction = direction
        setNeedsDisplay()
    }
}
