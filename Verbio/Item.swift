//
//  Item.swift
//  Verbio
//
//  Created by Justin Williams on 2/4/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
