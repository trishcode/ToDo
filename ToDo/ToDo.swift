//
//  ToDo.swift
//  ToDo
//
//  Created by Tricia Rudloff on 8/10/17.
//  Copyright © 2017 TrishCode. All rights reserved.
//

import Foundation
import RealmSwift

class ToDo: Object {
    
    dynamic var id: Int = 0
    dynamic var name: String = ""
    dynamic var priority: String = ""
    dynamic var date: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["priority", "date"]
    }

}
