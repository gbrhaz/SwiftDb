//
//  Persistable.swift
//

import Foundation

public protocol Identifiable: Codable {
    var id: Int { get }
}

public protocol Persistable: Codable {}

extension Persistable {
    static var table: String {
        return String(describing: self)
    }
}

extension Array: Persistable where Element: Persistable {}
