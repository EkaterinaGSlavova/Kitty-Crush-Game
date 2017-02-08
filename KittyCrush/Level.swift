//
//  Level.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/12/16.
//  Copyright © 2016 Ekaterina. All rights reserved.
//

import Foundation

let NumColumns = 9
let NumRows = 9

class Level {
    
    // Declare the 2Dimentional array that holds the Kitty object
    fileprivate var kitties = Array2D<Kitty>(columns: NumColumns, rows: NumRows)
    // Declare the 2Dimentional array that holds the Tile object
    fileprivate var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    fileprivate var bars = Array2D<Bars>(columns: NumColumns, rows: NumRows)
    fileprivate var possibleSwaps = Set<Swap>()
    
    var targetScore = 0
    var maximumMoves = 0
    fileprivate var comboMultiplier = 0
    
    init(filename: String) {
        
        
        // Load the file into a dictionary
        if let dictionary = Dictionary<String, AnyObject>.loadJSONFromFile(filename) {
            if let tilesArray: AnyObject = dictionary["tiles"] {
                for (row, rowArray) in (tilesArray as! [[Int]]).enumerated() {
                    
                    // revert the order of the rows because of the different coordinate systems
                    let tileRow = NumRows - row - 1
                    for (column, value) in rowArray.enumerated() {
                        if value == 1 {
                            // Create tile
                            tiles[column, tileRow] = Tile()
                        } else if value == 2 {
                            tiles[column, tileRow] = Tile()
                            bars[column, tileRow] = Bars()
                        }
                    }
                }
                targetScore = dictionary["targetScore"] as! Int
                maximumMoves = dictionary["moves"] as! Int
            }
        }
    }
    
    func shuffle() -> Set<Kitty> {
        
        var set: Set<Kitty>
        repeat {
            set = createInitialKitties()
            detectPossibleSwaps()
            print("possible swaps: \(possibleSwaps)")
        }
            while possibleSwaps.count == 0
        
        return set
    }
    
    fileprivate func createInitialKitties() -> Set<Kitty> {
        
        var set = Set<Kitty>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                
                if tiles[column, row] != nil {
                    var kittyType: KittyType
                    repeat {
                        kittyType = KittyType.random()
                    }
                        while (column >= 2 &&
                            kitties[column - 1, row]?.kittyType == kittyType &&
                            kitties[column - 2, row]?.kittyType == kittyType)
                            || (row >= 2 &&
                                kitties[column, row - 1]?.kittyType == kittyType &&
                                kitties[column, row - 2]?.kittyType == kittyType)
                    let kitty = Kitty(column: column, row: row, kittyType: kittyType)
                    kitties[column, row] = kitty
                    set.insert(kitty)
                }
                
            }
        }
        return set
    }

    func tileAtColumn(_ column: Int, row: Int) -> Tile? {
        
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    // Get the kitty from the 2D array and return it
    func kittyAtColumn(_ column: Int, row: Int) -> Kitty? {
        
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return kitties[column, row]
    }
    func barsAtColumn(_ column: Int, row: Int) -> Bars? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return bars[column, row]
    }
    func performSwap(_ swap: Swap) {
        
        let columnA = swap.kittyA.column
        let rowA = swap.kittyA.row
        let columnB = swap.kittyB.column
        let rowB = swap.kittyB.row
        
        kitties[columnA, rowA] = swap.kittyB
        swap.kittyB.column = columnA
        swap.kittyB.row = rowA
        
        kitties[columnB, rowB] = swap.kittyA
        swap.kittyA.column = columnB
        swap.kittyA.row = rowB
    }

    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let _ = barsAtColumn(column, row: row) { continue }
                
                if let kitty = kitties[column, row] {
                    
                    // Is it possible to swap this kitty with the one on the right
                    if column < NumColumns - 1 && barsAtColumn(column + 1, row: row) == nil {
                        // Have a kitty in this spot? If there is no tile, there is no kitty
                        if let other = kitties[column + 1, row] {
                            // Swap them
                            kitties[column, row] = other
                            kitties[column + 1, row] = kitty
                            
                            // Is either kitty now part of a chain
                            if hasChainAtColumn(column + 1, row: row) ||
                                hasChainAtColumn(column, row: row) {
                                    set.insert(Swap(kittyA: kitty, kittyB: other))
                            }
                            
                            // Swap them back
                            kitties[column, row] = kitty
                            kitties[column + 1, row] = other
                        }
                    }
                    
                    if row < NumRows - 1 && barsAtColumn(column, row: row + 1) == nil {
                        if let other = kitties[column, row + 1] {
                            kitties[column, row] = other
                            kitties[column, row + 1] = kitty
                            
                            // Is either kitty now part of a chain?
                            if hasChainAtColumn(column, row: row + 1) ||
                                hasChainAtColumn(column, row: row) {
                                set.insert(Swap(kittyA: kitty, kittyB: other))
                            }
                            
                            // Swap them back
                            kitties[column, row] = kitty
                            kitties[column, row + 1] = other
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    func isThereBarsInSwap(_ swap: Swap) -> Bool {
        return barsAtColumn(swap.kittyA.column, row: swap.kittyA.row) != nil || barsAtColumn(swap.kittyB.column, row: swap.kittyB.row) != nil
    }
    
    fileprivate func hasChainAtColumn(_ column: Int, row: Int) -> Bool {
        let kittyType = kitties[column, row]!.kittyType
        
        var horzLength = 1
        
        var i = column - 1
        while i >= 0 && kitties[i, row]?.kittyType == kittyType {
            i -= 1; horzLength += 1
        }

        var j = column + 1;
        while j < NumColumns && kitties[j, row]?.kittyType == kittyType {
            j += 1; horzLength  += 1
       }

        if horzLength >= 3 { return true }
        
        var vertLength = 1
        var k = row - 1
        
        while k >= 0 && kitties[column, k]?.kittyType == kittyType {
            k -= 1; vertLength += 1
        }
        
        var l = row + 1
        
        while l < NumRows && kitties[column, l]?.kittyType == kittyType {
            l += 1; vertLength += 1
        }

        return vertLength >= 3
    }
    fileprivate func detectHorizontalMatches() -> Set<Chain> {
        
        // Create new set to hold the horizontal chains
        var set = Set<Chain>()
        
        // Loop through the colums
        for row in 0..<NumRows {
            var column = 0
             while column < NumColumns - 2 {
                // Skip if there is a gap with no tile
                if let kitty = kitties[column, row] {
                    let matchType = kitty.kittyType
                    // Check if the next columns are with the same kitty type
                    if kitties[column + 1, row]?.kittyType == matchType && kitties[column+2, row]?.kittyType == matchType {
                        // Check if there is a kitty breaking the chain
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.addKitty(kitties[column, row]!)
                            column += 1
                        }
                        while column < NumColumns && kitties[column, row]?.kittyType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                column += 1
            }
        }
        return set
    }
    
    fileprivate func detectVerticalMatches() -> Set<Chain> {
        
        var set = Set<Chain>()
        
        for column in 0..<NumColumns {
            var row = 0
            while row < NumRows - 2 {
                if let kitty = kitties[column, row] {
                    let matchType = kitty.kittyType
                    
                    if kitties[column, row + 1]?.kittyType == matchType && kitties[column, row + 2]?.kittyType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.addKitty(kitties[column, row]!)
                            row += 1
                        }
                        while row < NumRows && kitties[column, row]?.kittyType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                row += 1
            }
        }
        return set
    }
    
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        removeKitties(horizontalChains)
        removeKitties(verticalChains)
        calculateScore(horizontalChains)
        calculateScore(verticalChains)
        removeBarsFromChains(horizontalChains)
        removeBarsFromChains(verticalChains)
        return horizontalChains.union(verticalChains)
    }
    
    fileprivate func removeKitties(_ chains: Set<Chain>) {
        for chain in chains {
            for kitty in chain.kitties {
                if barsAtColumn(kitty.column, row: kitty.row) == nil {
                    kitties[kitty.column, kitty.row] = nil
                }
            }
        }
    }
    
    fileprivate func removeBarsFromChains(_ chains: Set<Chain>) {
        var kittiesBehindBars = Set<Kitty>()
        for chain in chains {
            let chainKitties = chain.kitties
            for (index, kitty) in chainKitties.enumerated().reversed() {
                if let _ = barsAtColumn(kitty.column, row: kitty.row) {
                    kittiesBehindBars.insert(kitty)
                    chain.kitties.remove(at: index)
                }
            }
        }
        for kitty in kittiesBehindBars {
            if let bar = barsAtColumn(kitty.column, row: kitty.row) {
                bar.sprite.removeFromParent()
                bars[kitty.column, kitty.row] = nil
            }
        }
    }
    
    func fillHoles() -> [[Kitty]] {
        
        var columns = [[Kitty]]()
        
        for column in 0..<NumColumns {
            var array = [Kitty]()
            for row in 0..<NumRows {
                if tiles[column, row] != nil && kitties[column, row] == nil {
                    for lookup in (row + 1)..<NumRows {
                        if let kitty = kitties[column, lookup] {
                            
                            kitties[column, lookup] = nil
                            kitties[column, row] = kitty
                            kitty.row = row
                            
                            array.append(kitty)
                            
                            break
                        }
                    }
                }
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpKitties() -> [[Kitty]] {
        
        var columns = [[Kitty]]()
        var kittyType: KittyType = .unknown
        
        for column in 0..<NumColumns {
            var array = [Kitty]()
            var row = NumRows - 1
           while row >= 0 && kitties[column, row] == nil {
                if tiles[column, row] != nil {
                    var newKittyType: KittyType
                    repeat {
                        newKittyType = KittyType.random()
                    }
                    while newKittyType == kittyType
                    kittyType = newKittyType
                    
                    let kitty = Kitty(column: column, row: row, kittyType: kittyType)
                    kitties[column, row] = kitty
                    array.append(kitty)
                }
            row -= 1
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    fileprivate func calculateScore(_ chains:Set<Chain>) {
        
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    func resetMultiplier() {
        comboMultiplier = 1
    }
}

