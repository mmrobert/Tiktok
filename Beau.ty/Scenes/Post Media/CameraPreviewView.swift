//
//  CameraPreviewView.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-12-25.
//

import Foundation
import UIKit
import AVFoundation

class CameraPreviewView: UIView {
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer type for layer.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return cameraPreviewLayer.session
        }
        set {
            cameraPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
