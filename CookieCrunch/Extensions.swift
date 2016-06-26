//
//  Extensions.swift
//  CookieCrunch
//
//  Created by Jeremiah on 4/9/16.
//  Copyright © 2016 Jeremiah. All rights reserved.
//

import Foundation

extension Dictionary {
    static func loadJSONFromBundle(filename: String) -> Dictionary<String, AnyObject>? {
        if let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json") {
            do {
                let data = try NSData(contentsOfFile: path, options: NSDataReadingOptions())

                do {
                    let dictionary: AnyObject? = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                    
                    if let dictionary = dictionary as? Dictionary<String, AnyObject> {
                        return dictionary
                    }
                    else {
                        print("Level file '\(filename)' is not a valid JSON.")
                        return nil
                    }
                }
                catch {
                    print("Level file '\(filename)' does not contain a valid dictionary. Error: \(error)")
                    return nil
                }
            }
            catch {
                print("Could not read from level file '\(filename)'. Error: \(error)")
                return nil
            }
        }
        else {
            print("Could not find level file '\(filename)'.")
            return nil
        }
    }
}