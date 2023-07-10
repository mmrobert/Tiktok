//
//  AudioManager.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-12.
//

import Foundation
import AVFoundation

class AudioManager {
    
    static let shared = AudioManager()
    
    private init() {}
    
    func setAudioMode() {
        do {
            try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch (let err){
            print("setAudioMode error:" + err.localizedDescription)
        }
    }
}
