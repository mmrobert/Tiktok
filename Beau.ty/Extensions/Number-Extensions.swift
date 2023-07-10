//
//  Number Extensions.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-02-10.
//

import Foundation

extension Float {
    
    func format(maximumDigits:Int = 1, minimumDigits:Int = 1) -> String? {
        let number = NSNumber(value: self)
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = maximumDigits
        numberFormatter.minimumFractionDigits = minimumDigits
        return numberFormatter.string(from: number)
    }
}
