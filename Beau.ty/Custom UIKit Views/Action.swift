//
//  Action.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-12-28.
//

import Foundation

struct Action {
    var title: String
    var handler: ((String?) -> Void)?

    init(title: String, handler: ((String?) -> Void)? = nil) {
        self.title = title
        self.handler = handler
    }
}
