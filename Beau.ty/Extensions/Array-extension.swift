//
//  Array-extension.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-14.
//

import Foundation

class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}
