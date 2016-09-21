//
//  Level.swift
//  CookieCrunch
//
//  Created by Jeremiah on 4/5/16.
//  Copyright © 2016 Jeremiah. All rights reserved.
//

import Foundation

let NumColumns = 9
let NumRows = 9

class Level {
    private var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var possibleSwaps = Set<Swap>()
    
    var targetScore = 0
    var maximumMoves = 0
    
    private var comboMultiplier = 0
    
    func cookieAtColumn(column: Int, row: Int) -> Cookie? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return cookies[column, row]
    }
    
    func tileAtColumn(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    func shuffle() -> Set<Cookie> {
        var set: Set<Cookie>
        repeat {
            set = createInitialCookies()
            detectPossibleSwaps()
        }
        while possibleSwaps.count == 0
        
        return set
    }
    
    func performSwap(swap: Swap) {
        let columnA = swap.CookieA.column
        let rowA = swap.CookieA.row
        let columnB = swap.CookieB.column
        let rowB = swap.CookieB.row
        
        cookies[columnA, rowA] = swap.CookieB
        swap.CookieB.column = columnA
        swap.CookieB.row = rowA
        
        cookies[columnB, rowB] = swap.CookieA
        swap.CookieA.column = columnB
        swap.CookieA.row = rowB
    }
    
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0 ..< NumRows {
            for column in 0 ..< NumColumns {
                if let cookie = cookies[column, row] {
                    if column < NumColumns - 1 {
                        if let other = cookies[column + 1, row] {
                            cookies[column, row] = other
                            cookies[column + 1, row] = cookie
                            
                            if hasChainAtColumn(column + 1, row: row) || hasChainAtColumn(column, row: row) {
                                set.insert(Swap(CookieA: cookie, CookieB: other))
                            }
                            cookies[column, row] = cookie
                            cookies[column + 1, row] = other
                        }
                    }
                    if row < NumRows - 1 {
                        if let other = cookies[column, row + 1] {
                            cookies[column, row] = other
                            cookies[column, row + 1] = cookie
                            
                            if hasChainAtColumn(column, row: row + 1) || hasChainAtColumn(column, row: row) {
                                set.insert(Swap(CookieA: cookie, CookieB: other))
                            }
                            cookies[column, row] = cookie
                            cookies[column, row + 1] = other
                        }
                    }
                }
            }
        }
        possibleSwaps = set
    }
    
    private func hasChainAtColumn(column: Int, row: Int) -> Bool {
        let cookieType = cookies[column, row]!.cookieType
        
        var horzLength = 1
        for index in (column - 1).stride(through: 0, by: -1) {
            if cookies[index, row]?.cookieType == cookieType {
                horzLength += 1
            }
            else {
                break
            }
        }
        for index in (column + 1).stride(to: NumColumns, by: 1) {
            if cookies[index, row]?.cookieType == cookieType {
                horzLength += 1
            }
            else {
                break
            }
        }
        if horzLength >= 3 {
            return true
        }
        
        var vertLength = 1
        for index in (row - 1).stride(through: 0, by: -1) {
            if cookies[column, index]?.cookieType == cookieType {
                vertLength += 1
            }
            else {
                break
            }
        }
        for index in (row + 1).stride(to: NumRows, by: 1) {
            if cookies[column, index]?.cookieType == cookieType {
                vertLength += 1
            }
            else {
                break
            }
        }
        return vertLength >= 3
    }
    
    func isPossibleSwap(swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for row in 0 ..< NumRows {
            for var column in 0 ..< NumColumns - 2 {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    if cookies[column + 1, row]?.cookieType == matchType && cookies[column + 2, row]?.cookieType == matchType {
                        let chain = Chain(chainType: .Horizontal)
                        repeat {
                            chain.addCookie(cookies[column, row]!)
                            column += 1
                        }
                        while column < NumColumns && cookies[column, row]?.cookieType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                column += 1
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for column in 0 ..< NumColumns {
            for var row in 0 ..< NumRows - 2 {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    if cookies[column, row + 1]?.cookieType == matchType && cookies[column, row + 2]?.cookieType == matchType {
                        let chain = Chain(chainType: .Vertical)
                        repeat {
                            chain.addCookie(cookies[column, row]!)
                            row += 1
                        }
                        while row < NumRows && cookies[column, row]?.cookieType == matchType
                        
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
        
        removeCookies(horizontalChains)
        removeCookies(verticalChains)
        
        calculateScore(horizontalChains)
        calculateScore(verticalChains)
        
        return horizontalChains.union(verticalChains)
    }
    
    private func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.column, cookie.row] = nil
            }
        }
    }
    
    func fillHoles() -> [[Cookie]] {
        var columns = [[Cookie]]()
        
        for column in 0 ..< NumColumns {
            var array = [Cookie]()
            
            for row in 0 ..< NumRows {
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    for lookUp in (row + 1) ..< NumRows {
                        if let cookie = cookies[column, lookUp] {
                            cookies[column, lookUp] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            array.append(cookie)
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
    
    func topOffCookies() -> [[Cookie]] {
        var columns = [[Cookie]]()
        var cookieType: CookieType = .Unknown
        
        for column in 0 ..< NumColumns {
            var array = [Cookie]()
            
            for row in (NumRows - 1).stride(through: 0, by: -1) {
                if cookies[column, row] == nil && tiles[column, row] != nil {
                    var newCookieType: CookieType
                    
                    repeat {
                        newCookieType = CookieType.random()
                    }
                    while newCookieType == cookieType
                    cookieType = newCookieType
                    
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    array.append(cookie)
                }
            }
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    private func calculateScore(chains: Set<Chain>) {
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    
    private func createInitialCookies() -> Set<Cookie> {
        var set = Set<Cookie>()
        
        for row in 0 ..< NumRows {
            for column in 0 ..< NumColumns {
                if tiles[column, row] != nil {
                    var cookieType: CookieType
                    repeat {
                        cookieType = CookieType.random()
                    }
                    while (column >= 2 && cookies[column - 1, row]?.cookieType == cookieType && cookies[column - 2, row]?.cookieType == cookieType) ||
                        (row >= 2 && cookies[column, row - 1]?.cookieType == cookieType && cookies[column, row - 2]?.cookieType == cookieType)
                    
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                
                    set.insert(cookie)
                }
            }
        }
        return set
    }
    
    init(filename: String) {
        if let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename) {
            if let tilesArray: AnyObject = dictionary["tiles"] {
                for (row, rowArray) in (tilesArray as! [[Int]]).enumerate() {
                    let tileRow = NumRows - row - 1
                    for (column, value) in rowArray.enumerate() {
                        if value == 1 {
                            tiles[column, tileRow] = Tile()
                        }
                    }
                }
                targetScore = dictionary["targetScore"] as! Int
                maximumMoves = dictionary["moves"] as! Int
            }
        }
        else {
            print("Unable to load file.")
        }
    }
}