//
//  URLExtension.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-29.
//

import Foundation

extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        let schemeCopy = components?.scheme ?? ""
        components?.scheme = schemeCopy + scheme
        return components?.url
    }
}
