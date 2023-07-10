//
//  TimerRecordButton.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-12-24.
//

import Foundation
import UIKit

protocol TimerRecordButtonDelegate: AnyObject {
    func tapButton(buttonState: TimerRecordButton.ButtonState)
    func totalTimeStr(time: String)
    func reachMaxTime(totalSeconds: Int)
}

class TimerRecordButton: UIControl {
    
    private struct Constants {
        static let externalCircleFactor: CGFloat = 0.1
        static let cornerRadiusFactor: CGFloat = 0.24
        static let animationDuration: CGFloat = 0.5

        static let timeInterval: CGFloat = 1  // second
    }
    
    enum ButtonState {
        case record
        case stop(Int)
        case disabled
    }
    
    private let buttonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.green
        return view
    }()
    
    private var buttonState : ButtonState = .disabled {
        didSet {
            switch buttonState {
            case .record:
                self.animateRecord()
            case .stop( _):
                self.animateStop()
            case .disabled:
                self.animateDisabled()
            }
        }
    }
    
    private var timer = Timer()
    private var totalSeconds: Int = 0
    
    weak var delegate: TimerRecordButtonDelegate?
    public var maxRecordingTime: Int = 2 //  minutes
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func layoutSubviews() {
        self.drawExternalCircle()
        self.setupButtonView()
        super.layoutSubviews()
        self.addTarget(self, action: #selector(TimerRecordButton.didTouchUp), for: .touchUpInside)
    }
    
    @objc
    private func didTouchUp() {
        switch self.buttonState {
        case .record:
            self.buttonState = .stop(totalSeconds)
            self.stopTiming()
        case .stop:
            self.buttonState = .record
            self.startTiming()
        case .disabled:
            self.buttonState = .disabled
        }
        self.delegate?.tapButton(buttonState: self.buttonState)
    }
    
    private func drawExternalCircle() {
        
        let layer = CAShapeLayer()
        let radius = min(self.bounds.width, self.bounds.height) / 2
        let lineWidth = Constants.externalCircleFactor * radius
        layer.path = UIBezierPath(arcCenter: CGPoint(x: self.bounds.size.width / 2,
                                                     y: self.bounds.size.height / 2),
                                  radius: radius - lineWidth / 2,
                                  startAngle: 0,
                                  endAngle: 2 * CGFloat(Float.pi),
                                  clockwise: true
        ).cgPath
        layer.lineWidth = lineWidth
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.opacity = 1
        
        self.layer.addSublayer(layer)
    }
    
    private func setupButtonView() {
        self.addSubview(self.buttonView)
        let size = min(self.bounds.width, self.bounds.height) / 2
        NSLayoutConstraint.activate(
            [buttonView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
             buttonView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
             buttonView.widthAnchor.constraint(equalToConstant: size),
             buttonView.heightAnchor.constraint(equalToConstant: size)]
        )
        self.buttonView.layer.cornerRadius = size * Constants.cornerRadiusFactor
        self.buttonView.layer.masksToBounds = true
    }
    
    private func animateRecord() {
        UIView.animate(withDuration: Constants.animationDuration, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.buttonView.backgroundColor = UIColor.red
        }) { _ in }
    }
    
    private func animateStop() {
        UIView.animate(withDuration: Constants.animationDuration, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.buttonView.backgroundColor = UIColor.green
        }) { _ in }
    }
    
    private func animateDisabled() {
        UIView.animate(withDuration: Constants.animationDuration, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.buttonView.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        }) { _ in }
    }
    
    public func enable() {
        totalSeconds = 0
        self.delegate?.totalTimeStr(time: self.secondsToHMS(seconds: totalSeconds))
        self.buttonState = .stop(totalSeconds)
        if timer.isValid {
            timer.invalidate()
        }
    }
    
    public func disable() {
        totalSeconds = 0
        self.delegate?.totalTimeStr(time: self.secondsToHMS(seconds: totalSeconds))
        self.buttonState = .disabled
        if timer.isValid {
            timer.invalidate()
        }
    }
    
    func startTiming() {
        totalSeconds = 0
        self.delegate?.totalTimeStr(time: self.secondsToHMS(seconds: totalSeconds))
        if !timer.isValid {
            timer = Timer.scheduledTimer(timeInterval: Constants.timeInterval, target: self, selector: #selector(TimerRecordButton.timeCount), userInfo: nil, repeats: true)
        }
    }
    
    func stopTiming() {
        if timer.isValid {
            timer.invalidate()
        }
    }
    
    @objc private func timeCount() {
        totalSeconds += 1
        self.delegate?.totalTimeStr(time: self.secondsToHMS(seconds: totalSeconds))
        if totalSeconds >= self.maxRecordingTime * 60 {
            self.buttonState = .disabled
            self.delegate?.reachMaxTime(totalSeconds: totalSeconds)
            self.stopTiming()
        }
    }
    
    private func secondsToHMS(seconds: Int) -> String {
        let hour: Int = seconds / 3600
        let minute: Int = (seconds % 3600) / 60
        let second: Int = (seconds % 3600) % 60
        var timeStr = ""
        timeStr += String(format: "%02d", hour)
        timeStr += ":"
        timeStr += String(format: "%02d", minute)
        timeStr += ":"
        timeStr += String(format: "%02d", second)
        
        return timeStr
    }
}
