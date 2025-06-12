//
//  Item.swift
//  kairos24h
//
//  Created by Juan López Marín on 12/6/25.
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
