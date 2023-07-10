//
//  AppConfigurator.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-19.
//

import Foundation

struct AppConfigurator {
    
    static let shared = AppConfigurator()
    
    public var targetName: String? {
        return Bundle.main.infoDictionary?["TargetName"] as? String
    }
}
