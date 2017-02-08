//
//  Chain.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/17/16.
//  Copyright © 2016 Ekaterina. All rights reserved.
//

import Foundation

class Chain: Hashable, CustomStringConvertible {
    
    var kitties = [Kitty]()
    var score = 0
    
    enum ChainType: CustomStringConvertible {
        case horizontal
        case vertical
        
        var description: String {
            switch self {
            case .horizontal: return "Horizontal"
            case .vertical: return "Vertical"
            }
        }
    }
    
    var chainType: ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func addKitty(_ kitty: Kitty) {
        kitties.append(kitty)
    }
    
    func firstKitty() -> Kitty {
        return kitties[0]
    }
    
    func lastKitty() -> Kitty {
        return kitties[kitties.count - 1]
    }
    
    var length: Int {
        return kitties.count
    }
    
    var description: String {
        return "type:\(chainType) kitties:\(kitties)"
    }
    
    var hashValue: Int {
        return kitties.reduce(0) {$0.hashValue^$1.hashValue}
    }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
    
    return lhs.kitties == rhs.kitties
}
