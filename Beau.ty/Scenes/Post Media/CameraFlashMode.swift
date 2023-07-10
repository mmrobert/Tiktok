//
//  CameraFlashMode.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-12-25.
//

import Foundation
import UIKit
import AVFoundation

enum CameraTorchMode {
    case on
    case off
    
    func nextMode() -> CameraTorchMode {
        switch self {
        case .on:
            return .off
        case .off:
            return .on
        }
    }
    
    func torchModeButtonImage() -> UIImage? {
        switch self {
        case .on:
            return UIImage.flashOpen
        case .off:
            return UIImage.flashLock
        }
    }
    
    func deviceTorchMode() -> AVCaptureDevice.TorchMode {
        switch self {
        case .on:
            return AVCaptureDevice.TorchMode.on
        case .off:
            return AVCaptureDevice.TorchMode.off
        }
    }
}

extension AVCaptureVideoOrientation {
    
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        
        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }
        
        return uniqueDevicePositions.count
    }
}
