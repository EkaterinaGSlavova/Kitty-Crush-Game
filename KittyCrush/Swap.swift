//
//  Swap.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/14/16.
//  Copyright © 2016 Ekaterina. All rights reserved.
//

import Foundation

struct Swap: CustomStringConvertible, Hashable {
    
    let kittyA: Kitty
    let kittyB: Kitty
    
    init(kittyA: Kitty, kittyB: Kitty) {
        self.kittyA = kittyA
        self.kittyB = kittyB
    }
    
    var description: String {
        return "swap \(kittyA) with \(kittyB)"
    }
    var hashValue: Int {
        return kittyA.hashValue ^ kittyB.hashValue
    }
    
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.kittyA == rhs.kittyA && lhs.kittyB == rhs.kittyB) ||
        (lhs.kittyB == rhs.kittyA && lhs.kittyA == rhs.kittyB)
}