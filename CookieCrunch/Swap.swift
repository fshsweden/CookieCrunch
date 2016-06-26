//
//  Swap.swift
//  CookieCrunch
//
//  Created by Jeremiah on 4/10/16.
//  Copyright © 2016 Jeremiah. All rights reserved.
//

struct Swap: CustomStringConvertible, Hashable {
    let CookieA: Cookie
    let CookieB: Cookie
    
    init(CookieA: Cookie, CookieB: Cookie) {
        self.CookieA = CookieA
        self.CookieB = CookieB
    }
    
    var description: String {
        return "Swap \(CookieA) with \(CookieB)"
    }
    
    var hashValue: Int {
        return CookieA.hashValue ^ CookieB.hashValue
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.CookieA == rhs.CookieA && lhs.CookieB == rhs.CookieB) || (lhs.CookieB == rhs.CookieA && lhs.CookieA == rhs.CookieB)
}
