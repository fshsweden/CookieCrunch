//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Jeremiah on 4/5/16.
//  Copyright © 2016 Jeremiah. All rights reserved.
//

import SpriteKit

enum CookieType: Int, CustomStringConvertible {
    case Unknown = 0,
    Croissant,
    Cupcake,
    Danish,
    Donut,
    Macaroon,
    SugarCookie
    
    var spriteName: String {
        let spriteNames = [
            "Croissant",
            "Cupcake",
            "Danish",
            "Donut",
            "Macaroon",
            "SugarCookie"
        ]
        
        return spriteNames[rawValue - 1]
    }
    
    var spriteNameHighlighted: String {
        return spriteName + "-Highlighted"
    }
    
    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    
    var description: String {
        return spriteName
    }
}

class Cookie: CustomStringConvertible, Hashable {
    var column: Int
    var row: Int
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, cookieType: CookieType) {
        self.column = column
        self.row = row
        self.cookieType = cookieType
    }
    
    var description: String {
        return "Type:'\(cookieType)' Location:(\(column),\(row))"
    }
    
    var hashValue: Int {
        return row * 10 + column
    }
}

func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}