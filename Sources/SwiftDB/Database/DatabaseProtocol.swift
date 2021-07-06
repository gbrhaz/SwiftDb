//
//  DatabaseProtocol.swift
//  SwiftDB
//

import Foundation

public protocol DatabaseProtocol: class, ObservableStorage {
    func getAll<T: Persistable>(ofType type: T.Type) throws -> [T]
    func set<T: Persistable>(objects: [T]) throws

    func set<T>(object: T) throws where T: Persistable & Identifiable
    func get<T>(id: Int) throws -> T? where T: Persistable & Identifiable
}
