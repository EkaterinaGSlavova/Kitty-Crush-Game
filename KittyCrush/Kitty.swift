//
//  Kitty.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/12/16.
//  Copyright © 2016 Ekaterina. All rights reserved.
//

import SpriteKit

class Kitty: CustomStringConvertible, Hashable {
    
    var column: Int
    var row: Int
    let kittyType: KittyType
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, kittyType: KittyType) {
        self.column = column
        self.row = row
        self.kittyType = kittyType
    }
    var description: String {
        return "type:\(kittyType) sqare:(\(column), \(row))"
    }
    
    var hashValue: Int {
        return row*10 + column
    }
}

enum KittyType: Int, CustomStringConvertible {
    case unknown = 0, blackCat, brownCat, greyCat, orangeCat, tabbyCat, whiteCat
    
    var spriteName: String {
        
        let spriteNames = ["BlackCat", "BrownCat", "GreyCat", "OrangeCat", "TabbyCat", "WhiteCat"]
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> KittyType {
    
        return KittyType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    var description: String {
        return spriteName
    }
}

func ==(lhs: Kitty, rhs: Kitty) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}
