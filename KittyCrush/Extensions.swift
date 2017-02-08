//
//  Extensions.swift
//  KittyCrush
//
//  Created by Ekaterina on 2/14/16.
//  Copyright © 2016 Ekaterina. All rights reserved.
//
import Foundation

extension Dictionary {

    // Loads a JSON file from the app bundle into a new dictionary
    static func loadJSONFromFile(_ filename: String) -> Dictionary<String, AnyObject>? {
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            
            var error: NSError?
            let data: Data?
            do {
                data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions())
            } catch let error1 as NSError {
                error = error1
                data = nil
            }
            if let data = data {
                
                let dictionary: Any?
                do {
                    dictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                } catch let error1 as NSError {
                    error = error1
                    dictionary = nil
                }
                if let dictionary = dictionary as? Dictionary<String, AnyObject> {
                    return dictionary
                } else {
                    print("Level file '\(filename)' is not valid JSON: \(error!)")
                    return nil
                }
            } else {
                print("Could not load level file: \(filename), error: \(error!)")
                return nil
            }
        } else {
            print("Could not find level file: \(filename)")
            return nil
        }
    }
}

