//
//  Array2D.swift
//  CookieCrunch
//
//  Created by Jeremiah on 4/5/16.
//  Copyright © 2016 Jeremiah. All rights reserved.
//

struct Array2D<T> {
    let columns: Int
    let rows: Int
    private var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(count: columns * rows, repeatedValue: nil)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[columns * row + column]
        }
        set {
            array[columns * row + column] = newValue
        }
    }
}
