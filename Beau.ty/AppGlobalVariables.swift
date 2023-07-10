//
//  AppGlobalVariables.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-19.
//

import Foundation
import Combine

class AppGlobalVariables: ObservableObject {
    
    static let shared = AppGlobalVariables()
    
    private init() {}
    
    @Published var currentVC: ViewControllerID = ViewControllerID.None
}

enum ViewControllerID: String {
    // home tab
    case HomeViewController
    
    // post tab
    case CreateMediaViewController
    case ReviewVideoViewController
    case PostVideoViewController
    case HashtagsInputViewController
    
    // none
    case None
}
