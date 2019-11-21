//
//  Persistable.swift
//  
//
//  Created by Harry Richardson on 21/11/2019.
//

import Foundation

public protocol Persistable: Codable
{
    var id: String { get }
}

extension Persistable {
    static var table: String {
        return String(describing: self)
    }
}
