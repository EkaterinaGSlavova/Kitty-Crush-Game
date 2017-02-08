//
//  Array2D.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/12/16.
//  Copyright © 2016 Ekaterina. All rights reserved.
//

import Foundation

// Define generic struct and subscript for the columns 

struct Array2D<T> {
    let columns: Int
    let rows: Int
    fileprivate var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(repeating: nil, count: rows*columns)
    }
    
    subscript(column:Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        } set {
            array[row*columns + column] = newValue
        }
    }
}
